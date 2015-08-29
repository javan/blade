require "faye/websocket"
require "useragent"

module Blade::Server
  extend self
  include Blade::Component

  WEBSOCKET_PATH = "/blade/websocket"

  def start
    Faye::WebSocket.load_adapter("thin")
    Rack::Server.start(app: app, Port: Blade.config.port, server: "thin")
  end

  def websocket_url(path = "")
    Blade.url(WEBSOCKET_PATH + path)
  end

  def client
    @client ||= Faye::Client.new(websocket_url)
  end

  private
    def app
      Rack::Builder.app do
        run Blade::RackAdapter.new
      end
    end
end
