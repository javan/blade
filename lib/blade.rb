require "active_support/all"
require "eventmachine"
require "faye"
require "pathname"
require "yaml"

require "blade/version"
require "blade/cli"

module Blade
  extend self

  CONFIG_DEFAULTS = {
    framework: :qunit,
    port: 9876,
    build: { path: "." }
  }

  CONFIG_FILENAMES = %w( blade.yml .blade.yml )

  @components = []

  def register_component(component)
    @components << component
  end

  require "blade/component"
  require "blade/server"

  autoload :Model, "blade/model"
  autoload :Assets, "blade/assets"
  autoload :Config, "blade/config"
  autoload :RackAdapter, "blade/rack/adapter"
  autoload :RackRouter, "blade/rack/router"
  autoload :Session, "blade/session"
  autoload :TestResults, "blade/test_results"

  delegate :subscribe, :publish, to: Server

  attr_reader :config

  def start(options = {})
    return if running?
    ensure_tmp_path

    initialize!(options)
    load_interface

    handle_exit

    EM.run do
      @components.each { |c| c.try(:start) }
      @running = true
    end
  end

  def stop
    return if @stopping
    @stopping = true
    @components.each { |c| c.try(:stop) }
    EM.stop if EM.reactor_running?
    @running = false
  end

  def running?
    @running
  end

  def initialize!(options = {})
    return if @initialized
    @initialized = true

    options = CONFIG_DEFAULTS.deep_merge(blade_file_options).deep_merge(options)
    @config = Blade::Config.new options

    config.load_paths = Array(config.load_paths)
    config.logical_paths = Array(config.logical_paths)

    if config.build?
      config.build.logical_paths = Array(config.build.logical_paths)
      config.build.path ||= "."
    end

    config.plugins ||= {}

    load_requires
    load_plugins
    load_adapter
  end

  def build
    initialize!
    Assets.build
  end

  def url(path = "/")
    "http://#{Server.host}:#{config.port}#{path}"
  end

  def root_path
    Pathname.new(File.dirname(__FILE__)).join("../")
  end

  def tmp_path
    Pathname.new(".").join("tmp/blade")
  end

  def ensure_tmp_path
    tmp_path.mkpath
  end

  def clean_tmp_path
    tmp_path.rmtree if tmp_path.exist?
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

    def blade_file_options
      if filename = CONFIG_FILENAMES.detect { |name| File.exists?(name) }
        YAML.load_file(filename)
      else
        {}
      end
    end

    def load_interface
      require "blade/interface/#{config.interface}"
    end

    def load_adapter
      require "blade/#{config.framework}_adapter"
    end

    def load_requires
      Array(config.require).each do |path|
        require path
      end
    end

    def load_plugins
      config.plugins.keys.each do |name|
        require "blade/#{name}_plugin"
      end
    end
end
