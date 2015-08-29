require "sprockets"

module Blade::Assets
  extend self

  @environments = {}

  def environment(name = :blade)
    @environments[name] ||= Sprockets::Environment.new do |env|
      env.cache = Sprockets::Cache::FileStore.new(Blade.tmp_path.join(name.to_s))

      send("#{name}_load_paths").each do |path|
        env.append_path(path)
      end

      env.context_class.class_eval do
        extend Forwardable
        def_delegators "Blade::Assets", :environment, :logical_paths

        def with_asset(path, env_name)
          if asset = environment(env_name)[path]
            depend_on(asset.pathname)
            yield(asset)
          end
        end

        def render_asset(path, env_name)
          with_asset(path, env_name) { |asset| asset.to_s }
        end
      end
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
    Blade.config.load_paths.map { |a| Pathname.new(a) }
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
      environment_for(:user)[logical_path].mtime
    rescue Exception => e
      e.to_s
    end

    def gem_pathname(gem_name)
      gemspec = Gem::Specification.find_by_name(gem_name)
      Pathname.new(gemspec.gem_dir)
    end
end
