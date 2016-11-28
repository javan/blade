require "sprockets"

module Blade::Assets
  autoload :Builder, "blade/assets/builder"

  extend self

  def environment
    @environment ||= Sprockets::Environment.new do |env|
      env.cache = Sprockets::Cache::FileStore.new(Blade.tmp_path)

      %w( blade user adapter ).each do |name|
        send("#{name}_load_paths").each do |path|
          env.append_path(path)
        end
      end

      env.context_class.class_eval do
        delegate :logical_paths, to: Blade::Assets
      end
    end
  end

  def build
    if Blade.config.build
      Builder.new(environment).build
    end
  end

  def logical_paths(type = nil)
    paths = Blade.config.logical_paths
    paths.select! { |path| File.extname(path) == ".#{type}" } if type
    paths
  end

  def blade_load_paths
    [ Blade.root_path.join("assets") ]
  end

  def user_load_paths
    Blade.config.load_paths.flat_map do |load_path|
      if load_path.is_a?(Hash)
        load_path.flat_map do |gem_name, paths|
          Array(paths).map{ |path| gem_pathname(gem_name).join(path) }
        end
      else
        Pathname.new(load_path)
      end
    end
  end

  def adapter_load_paths
    gem_name = "blade-#{Blade.config.framework}_adapter"
    [ gem_pathname(gem_name).join("assets") ]
  end

  def watch_logical_paths
    @mtimes = get_mtimes

    EM.add_periodic_timer(1) do
      mtimes = get_mtimes
      unless mtimes == @mtimes
        @mtimes = mtimes
        Blade.publish("/assets", changed: @mtimes)
      end
    end
  end

  private
    def get_mtimes
      {}.tap do |mtimes|
        Blade.config.logical_paths.each do |path|
          mtimes[path] = get_mtime(path)
        end
      end
    end

    def get_mtime(logical_path)
      environment[logical_path].mtime
    rescue Exception => e
      e.to_s
    end

    def gem_pathname(gem_name)
      gemspec = Gem::Specification.find_by_name(gem_name)
      Pathname.new(gemspec.gem_dir)
    end
end
