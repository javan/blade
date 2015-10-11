require "faye/websocket"
require "useragent"

module Blade::Server
  extend self
  include Blade::Component

  WEBSOCKET_PATH = "/blade/websocket"

  def start
    Faye::WebSocket.load_adapter("thin")
    Thin::Logging.silent = true
    Thin::Server.start("localhost", Blade.config.port, app, signals: false)
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
