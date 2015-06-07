require "eventmachine"
require "faye"
require "pathname"
require "ostruct"

require "active_support/core_ext/string/inflections"
require "active_support/core_ext/hash"

require "blade_runner/version"
require "blade_runner/concerns/knife"
require "blade_runner/assets"
require "blade_runner/server"
require "blade_runner/session_manager"
require "blade_runner/console"
require "blade_runner/ci"
require "blade_runner/test_results"
require "blade_runner/combined_test_results"

module BladeRunner
  extend self

  ALLOWED_MODES = [:console, :ci]

  DEFAULT_MODE = ALLOWED_MODES.first
  DEFAULT_PORT = 9876

  attr_reader :config, :plugins

  def start(options = {})
    @options = options.with_indifferent_access
    @runnables = []

    handle_exit
    setup_config!
    setup_plugins!

    EM.run do
      @runnables.unshift(server, interface)
      @runnables.each { |r| r.start if r.respond_to?(:start) }
    end
  end

  def stop
    return if @stopping
    @stopping = true
    @runnables.each { |r| r.stop if r.respond_to?(:stop) }
    EM.stop if EM.reactor_running?
  end

  def blade_url(path = "")
    "http://localhost:#{config.port}#{path}"
  end

  def assets
    @assets ||= Assets.new
  end

  def server
    @server ||= Server.new
  end

  def client
    server.client
  end

  def sessions
    @session ||= SessionManager.new
  end

  def interface
    @interface ||=
      case config.mode
      when :ci then CI.new
      when :console then Console.new
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
      options[:asset_paths] = Array(options[:asset_paths])
      options[:test_scripts] = Array(options[:test_scripts])

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
