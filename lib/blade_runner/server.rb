require "faye"
require "sprockets"

module BladeRunner
  class Server
    include Knife

    def start
      @pid = fork do
        STDIN.reopen("/dev/null")
        STDOUT.reopen("/dev/null", "a")
        STDERR.reopen("/dev/null", "a")
        Rack::Server.start(app: app, Port: config.port, server: "puma", quiet: true, environment: "development")
      end
      sleep 2
    end

    def stop
      Process.kill("INT", @pid)
      Process.wait(@pid)
    end

    private
      def app
        _sprockets = sprockets
        _faye = faye

        Rack::Builder.app do
          map "/" do
            run _sprockets
          end

          map "/faye" do
            run _faye
          end
        end
      end

      def sprockets
        @sprockets ||= Sprockets::Environment.new do |env|
          env.cache = Sprockets::Cache::FileStore.new(tmp_path)

          asset_paths.each do |path|
            env.append_path(path)
          end
        end
      end

      def faye
        @faye ||= Faye::RackAdapter.new(mount: "/", timeout: 25)
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
  end
end
