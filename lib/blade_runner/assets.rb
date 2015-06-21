require "sprockets"

module BladeRunner::Assets
  extend self

  def environment
    @environment ||= Sprockets::Environment.new do |env|
      env.cache = Sprockets::Cache::FileStore.new(BR.tmp_path)

      load_paths.each do |path|
        env.append_path(path)
      end

      env.context_class.class_eval do
        include BladeRunner::TemplateHelper
      end
    end
  end

  def logical_paths(type = nil)
    paths = BR.config.logical_paths
    paths.select! { |path| File.extname(path) == ".#{type}" } if type
    paths
  end

  def load_paths
    local_load_paths + remote_load_paths
  end

  def local_load_paths
    %w( assets ).map { |a| BR.root_path.join(a) } + [ faye_load_path ]
  end

  def remote_load_paths
    BR.config.load_paths.map { |a| Pathname.new(a) }
  end

  def watch_logical_paths
    @mtimes = get_mtimes

    EM.add_periodic_timer(1) do
      mtimes = get_mtimes
      unless mtimes == @mtimes
        @mtimes = mtimes
        BR.publish("/assets", changed: @mtimes)
      end
    end
  end

  private
    def get_mtimes
      {}.tap do |mtimes|
        BR.config.logical_paths.each do |path|
          mtimes[path] = get_mtime(path)
        end
      end
    end

    def get_mtime(logical_path)
      environment[logical_path].mtime
    rescue Exception => e
      e.to_s
    end

    def faye_load_path
      gemspec = Gem::Specification.find_by_name("faye")
      Pathname.new(gemspec.gem_dir).join("lib")
    end
end
