require "pathname"
require "ostruct"

require "blade_runner/version"
require "blade_runner/base"
require "blade_runner/server"
require "blade_runner/browsers"
require "blade_runner/file_watcher"
require "blade_runner/console"

class BladeRunner
  attr_reader :config

  def initialize(options = {})
    @config = OpenStruct.new(options)

    config.port ||= 9876
    config.asset_paths = Array(config.asset_paths)
    config.test_scripts = Array(config.test_scripts)
    config.watch_files = Array(config.watch_files)
  end

  SIGNALS = %w( INT )

  def start
    SIGNALS.each do |signal|
      trap(signal) { stop }
    end

    @children = [server, browsers, file_watcher, console].flatten
    @children.each(&:start)
  end

  def stop
    return if @stopping
    @stopping = true
    @children.each { |c| c.stop rescue nil }
  ensure
    exit
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
    @server ||= Server.new(self)
  end

  def client
    @client ||= Faye::Client.new("http://localhost:#{config.port}/faye")
  end

  def browsers
    @browsers ||= descendants(Browser).map { |c| c.new(self) }.select(&:supported?)
  end

  def file_watcher
    @file_watcher ||= FileWatcher.new(self)
  end

  def console
    @console ||= Console.new(self)
  end

  private
    def clean
      FileUtils.rm_rf(tmp_path)
      FileUtils.mkdir_p(tmp_path)
    end

    def descendants(klass)
      ObjectSpace.each_object(Class).select { |c| c < klass }
    end
end
