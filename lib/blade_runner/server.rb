require "faye/websocket"

class BladeRunner::Server
  include BladeRunner::Knife

  def start
    Faye::WebSocket.load_adapter("thin")
    Rack::Server.start(app: app, Port: config.port, server: "thin")
  end

  def stop
  end

  private
    def app
      Rack::Builder.app do
        map "/" do
          run BladeRunner.assets.environment
        end

        map "/faye" do
          run BladeRunner.bayeux
        end
      end
    end
end
