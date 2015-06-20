require "blade_runner/version"

require "eventmachine"
require "faye"
require "pathname"
require "ostruct"

require "active_support/core_ext/string/inflections"
require "active_support/core_ext/hash"

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
  autoload :Session, "blade_runner/session"
  autoload :TestResults, "blade_runner/test_results"
  autoload :CombinedTestResults, "blade_runner/combined_test_results"
  autoload :Console, "blade_runner/interface/console"
  autoload :CI, "blade_runner/interface/ci"

  extend Forwardable
  def_delegators "Server.client", :subscribe, :publish

  ALLOWED_MODES = [:console, :ci]

  DEFAULT_MODE = ALLOWED_MODES.first
  DEFAULT_PORT = 9876

  attr_reader :config, :plugins

  def start(options = {})
    @options = options.with_indifferent_access

    handle_exit
    setup_config!
    setup_plugins!
    interface

    EM.run do
      @components.each { |c| c.start if c.respond_to?(:start) }
    end
  end

  def stop
    return if @stopping
    @stopping = true
    @components.each { |c| c.stop if c.respond_to?(:stop) }
    EM.stop if EM.reactor_running?
  end

  def url(path = "")
    "http://localhost:#{config.port}#{path}"
  end

  def interface
    @interface ||=
      case config.mode
      when :ci then CI
      when :console then Console
      end
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

    def setup_config!
      ignore_options = ALLOWED_MODES + [:plugins]

      options = @options.except(ignore_options)
      options[:mode] = DEFAULT_MODE unless ALLOWED_MODES.include?(options[:mode])

      if options_for_mode = @options[options[:mode]]
        options.merge! options_for_mode.except(ignore_options)
      end

      options[:port] ||= DEFAULT_PORT
      options[:load_paths] = Array(options[:load_paths])
      options[:logical_paths] = Array(options[:logical_paths])

      @config = OpenStruct.new(options)
    end

    def setup_plugins!
      @plugins = OpenStruct.new

      plugin_config = @options[:plugins] || {}

      if plugins_for_mode = (@options[config.mode] || {})[:plugins]
        plugin_config.merge! plugins_for_mode
      end

      plugin_config.each do |name, plugin_config|
        plugins[name] = OpenStruct.new(config: OpenStruct.new(plugin_config))
        plugin_path = "blade_runner/#{name}"
        require plugin_path
        @runnables << plugin_path.camelize.safe_constantize
      end
    end
end

BR = BladeRunner
