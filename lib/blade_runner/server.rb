require "faye"

class BladeRunner::Server
  include BladeRunner::Knife

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
      _faye = faye

      Rack::Builder.app do
        map "/" do
          run BladeRunner.assets.environment
        end

        map "/faye" do
          run _faye
        end
      end
    end

    def faye
      @faye ||= Faye::RackAdapter.new(mount: "/", timeout: 25)
    end
end
