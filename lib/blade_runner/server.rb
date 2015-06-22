require "faye/websocket"
require "useragent"

module BladeRunner::Server
  extend self
  include BladeRunner::Component

  WEBSOCKET_PATH = "/blade_runner/websocket"

  def start
    Faye::WebSocket.load_adapter("thin")
    Rack::Server.start(app: app, Port: BR.config.port, server: "thin")
  end

  def websocket_url(path = "")
    BR.url(WEBSOCKET_PATH + path)
  end

  def client
    @client ||= Faye::Client.new(websocket_url)
  end

  private
    def app
      Rack::Builder.app do
        run BladeRunner::RackAdapter.new
      end
    end
end
