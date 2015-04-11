require "eventmachine"
require "pathname"
require "ostruct"

require "blade_runner/version"
require "blade_runner/concerns/knife"
require "blade_runner/server"
require "blade_runner/browsers"
require "blade_runner/file_watcher"
require "blade_runner/console"
require "blade_runner/ci"

module BladeRunner
  extend self

  attr_reader :config

  SIGNALS = %w( INT )

  def start(options = {})
    SIGNALS.each do |signal|
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
    config.watch_files = Array(config.watch_files)

    plugins = config.plugins || {}
    config.plugins = OpenStruct.new
    plugins.each do |name, plugin_config|
      config.plugins[name] = OpenStruct.new(plugin_config)
      require "blade_runner/#{name}"
    end

    clean

    EM.run do
      @children = [server, browsers, runner_for_mode].flatten
      @children.each(&:start)
    end
  end

  def stop
    return if @stopping
    @stopping = true
    @children.each { |c| c.stop rescue nil }
    EM.stop_event_loop
  rescue
    nil
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

  def server
    @server ||= Server.new
  end

  def client
    @client ||= Faye::Client.new("http://localhost:#{config.port}/faye")
  end

  def browsers
    @browsers ||= Browser.subclasses.map { |c| c.new }.select(&:supported?)
  end

  def file_watcher
    @file_watcher ||= FileWatcher.new
  end

  def console
    @console ||= Console.new
  end

  def ci
    @ci ||= CI.new
  end

  private
    ALLOWED_MODES = [:ci, :console]

    def runner_for_mode
      if ALLOWED_MODES.include?(config.mode)
        send(config.mode)
      end
    end

    def clean
      FileUtils.rm_rf(tmp_path)
      FileUtils.mkdir_p(tmp_path)
    end
end
