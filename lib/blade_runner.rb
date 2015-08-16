require "active_support/core_ext/hash"
require "eventmachine"
require "faye"
require "pathname"
require "ostruct"
require "yaml"

require "blade_runner/version"
require "blade_runner/cli"

module BladeRunner
  extend self

  @components = []

  def register_component(component)
    @components << component
  end

  require "blade_runner/component"
  require "blade_runner/server"

  autoload :Model, "blade_runner/model"
  autoload :Assets, "blade_runner/assets"
  autoload :RackAdapter, "blade_runner/rack_adapter"
  autoload :Session, "blade_runner/session"
  autoload :TestResults, "blade_runner/test_results"
  autoload :CombinedTestResults, "blade_runner/combined_test_results"

  extend Forwardable
  def_delegators "Server.client", :subscribe, :publish

  DEFAULT_PORT = 9876

  attr_reader :config, :plugins

  def start(options = {})
    return if running?
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

  def url(path = "")
    "http://localhost:#{config.port}#{path}"
  end

  def root_path
    Pathname.new(File.dirname(__FILE__)).join("../")
  end

  def tmp_path
    Pathname.new(".").join("tmp/blade_runner")
  end

  private
    def handle_exit
      %w( INT ).each do |signal|
        trap(signal) { stop }
      end

      at_exit do
        stop
        exit $!.status if $!.is_a?(SystemExit)
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

      options[:port] ||= DEFAULT_PORT
      options[:load_paths] = Array(options[:load_paths])
      options[:logical_paths] = Array(options[:logical_paths])

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
      require "blade_runner/interface/#{config.interface}"
    end

    def load_adapter!
      require "blade_runner/#{config.framework}_adapter"
    end

    def load_plugins!
      plugins.to_h.keys.each do |name|
        require "blade_runner/#{name}_plugin"
      end
    end
end

BR = BladeRunner
