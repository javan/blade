require "sprockets"

class BladeRunner::Assets
  include BladeRunner::Knife

  def start
    watch_test_scripts_for_changes
  end

  def stop
  end

  def environment
    @environment ||= Sprockets::Environment.new do |env|
      env.cache = Sprockets::Cache::FileStore.new(tmp_path)

      asset_paths.each do |path|
        env.append_path(path)
      end
    end
  end

  def asset_paths
    local_asset_paths + remote_asset_paths
  end

  def local_asset_paths
    %w( assets ).map { |a| root_path.join(a) }
  end

  def remote_asset_paths
    config.asset_paths.map { |a| Pathname.new(a) }
  end

  private
    def watch_test_scripts_for_changes
      @mtimes = get_mtimes

      EM.add_periodic_timer(1) do
        mtimes = get_mtimes
        unless mtimes == @mtimes
          @mtimes = mtimes
          publish("/assets", changed: @mtimes)
        end
      end
    end

    def get_mtimes
      {}.tap do |mtimes|
        config.test_scripts.each do |script|
          mtimes[script] = environment[script].mtime
        end
      end
    end
end
