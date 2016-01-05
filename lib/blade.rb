require "active_support/all"
require "eventmachine"
require "faye"
require "pathname"
require "ostruct"
require "yaml"

require "blade/version"
require "blade/cli"

module Blade
  extend self

  @components = []

  def register_component(component)
    @components << component
  end

  require "blade/component"
  require "blade/server"

  autoload :Model, "blade/model"
  autoload :Assets, "blade/assets"
  autoload :RackAdapter, "blade/rack/adapter"
  autoload :RackRouter, "blade/rack/router"
  autoload :Session, "blade/session"
  autoload :TestResults, "blade/test_results"

  delegate :subscribe, :publish, to: Server

  DEFAULT_FRAMEWORK = :qunit
  DEFAULT_PORT = 9876

  attr_reader :config, :plugins

  def start(options = {})
    return if running?
    clean_tmp_path

    initialize!(options)
    load_interface!

    handle_exit

    EM.run do
      @components.each { |c| c.start if c.respond_to?(:start) }
      @running = true
    end
  end

  def stop
    return if @stopping
    @stopping = true
    @components.each { |c| c.stop if c.respond_to?(:stop) }
    EM.stop if EM.reactor_running?
    @running = false
  end

  def running?
    @running
  end

  def initialize!(options = {})
    @options ||= {}.with_indifferent_access
    @options.merge! options

    setup_config!
    load_plugins!
    load_adapter!
  end

  def url(path = "/")
    "http://localhost:#{config.port}#{path}"
  end

  def root_path
    Pathname.new(File.dirname(__FILE__)).join("../")
  end

  def tmp_path
    Pathname.new(".").join("tmp/blade")
  end

  def clean_tmp_path
    tmp_path.rmtree if tmp_path.exist?
    tmp_path.mkpath
  end

  private
    def handle_exit
      at_exit do
        stop
        exit $!.status if $!.is_a?(SystemExit)
      end

      %w( INT ).each do |signal|
        trap(signal) { exit(1) }
      end
    end

    def load_config_file!
      filename = ".blade.yml"
      if File.exists?(filename)
        @options.reverse_merge!(YAML.load_file(filename))
      end
    end

    def setup_config!
      load_config_file!
      options = @options.except(:plugins)

      if options_for_interface = @options[options[:interface]]
        options.merge! options_for_interface
      end

      options[:framework] ||= DEFAULT_FRAMEWORK
      options[:port] ||= DEFAULT_PORT
      options[:load_paths] = Array(options[:load_paths])
      options[:logical_paths] = Array(options[:logical_paths])

      if build_options = options.delete(:build)
        build_options[:logical_paths] = Array(build_options[:logical_paths])
        build_options[:path] ||= "."
        options[:build] = OpenStruct.new(build_options)
      end

      @config = OpenStruct.new(options)

      setup_plugin_config!
    end

    def setup_plugin_config!
      @plugins = OpenStruct.new

      plugin_options = @options[:plugins] || {}

      plugin_options.each do |name, plugin_config|
        plugins[name] = OpenStruct.new(config: OpenStruct.new(plugin_config))
      end
    end

    def load_interface!
      require "blade/interface/#{config.interface}"
    end

    def load_adapter!
      require "blade/#{config.framework}_adapter"
    end

    def load_plugins!
      plugins.to_h.keys.each do |name|
        require "blade/#{name}_plugin"
      end
    end
end
