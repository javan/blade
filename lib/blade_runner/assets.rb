require "sprockets"

class BladeRunner::Assets
  include BladeRunner::Knife

  def environment
    @environment ||= Sprockets::Environment.new do |env|
      env.cache = Sprockets::Cache::FileStore.new(tmp_path)

      load_paths.each do |path|
        env.append_path(path)
      end

      env.context_class.class_eval do
        include BladeRunner::Knife
      end
    end
  end

  def load_paths
    local_load_paths + remote_load_paths
  end

  def local_load_paths
    %w( assets ).map { |a| root_path.join(a) }
  end

  def remote_load_paths
    config.load_paths.map { |a| Pathname.new(a) }
  end

  def watch_logical_paths
    @mtimes = get_mtimes

    EM.add_periodic_timer(1) do
      mtimes = get_mtimes
      unless mtimes == @mtimes
        @mtimes = mtimes
        publish("/assets", changed: @mtimes)
      end
    end
  end

  private
    def get_mtimes
      {}.tap do |mtimes|
        config.logical_paths.each do |path|
          mtimes[path] = environment[path].mtime
        end
      end
    end
end
