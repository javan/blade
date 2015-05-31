require "eventmachine"
require "faye"
require "pathname"
require "ostruct"

require "blade_runner/version"
require "blade_runner/concerns/knife"
require "blade_runner/assets"
require "blade_runner/server"
require "blade_runner/console"
require "blade_runner/ci"
require "blade_runner/test_results"

module BladeRunner
  extend self

  attr_reader :config

  def start(options = {})
    %w( INT ).each do |signal|
      trap(signal) { stop }
    end

    at_exit do
      stop
      exit $!.status if $!.is_a?(SystemExit)
    end

    @config = OpenStruct.new(options)

    config.port ||= 9876
    config.mode ||= :console
    config.asset_paths = Array(config.asset_paths)
    config.test_scripts = Array(config.test_scripts)

    plugins = config.plugins || {}
    config.plugins = OpenStruct.new
    plugins.each do |name, plugin_config|
      config.plugins[name] = OpenStruct.new(plugin_config)
      require "blade_runner/#{name}"
    end

    #clean

    EM.run do
      @runnables = [assets, server, interface]
      @runnables.each { |r| r.start if r.respond_to?(:start) }
    end
  end

  def stop
    return if @stopping
    @stopping = true
    @runnables.each { |r| r.stop if r.respond_to?(:stop) }
    EM.stop if EM.reactor_running?
  end

  def test_url
    "http://localhost:#{config.port}/blade/#{config.framework}.html"
  end

  def lib_path
    Pathname.new(File.dirname(__FILE__))
  end

  def root_path
    lib_path.join("../")
  end

  def tmp_path
    root_path.join("tmp")
  end

  def assets
    @assets ||= Assets.new
  end

  def server
    @server ||= Server.new
  end

  def bayeux
    @bayeux ||= Faye::RackAdapter.new(mount: "/", timeout: 25)
  end

  def client
    @client ||= Faye::Client.new("http://localhost:#{config.port}/faye")
  end

  def interface
    @interface ||=
      case config.mode
      when :ci then CI.new
      when :console then Console.new
      end
  end

  private
    def clean
      FileUtils.rm_rf(tmp_path)
      FileUtils.mkdir_p(tmp_path)
    end
end
