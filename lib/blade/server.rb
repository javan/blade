require "faye/websocket"
require "useragent"

module Blade::Server
  extend self
  include Blade::Component

  WEBSOCKET_PATH = "/blade/websocket"

  def start
    Faye::WebSocket.load_adapter("thin")
    Thin::Logging.silent = true
    Thin::Server.start(host, Blade.config.port, app, signals: false)
  end

  def host
    Thin::Server::DEFAULT_HOST
  end

  def websocket_url(path = "")
    Blade.url(WEBSOCKET_PATH + path)
  end

  def client
    @client ||= Faye::Client.new(websocket_url)
  end

  def subscribe(channel)
    client.subscribe(channel) do |message|
      yield message.with_indifferent_access
    end
  end

  def publish(channel, message)
    client.publish(channel, message)
  end

  private
    def app
      Rack::Builder.app do
        use Rack::ShowExceptions
        run Blade::RackAdapter.new
      end
    end
end
