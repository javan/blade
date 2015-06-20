require "faye/websocket"
require "useragent"

module BladeRunner::Server
  extend self
  include BladeRunner::Component

  WEBSOCKET_PATH = "/blade/websocket"

  def start
    Faye::WebSocket.load_adapter("thin")
    Rack::Server.start(app: app, Port: BR.config.port, server: "thin")
  end

  def websocket_url(path = "")
    BR.blade_url(WEBSOCKET_PATH + path)
  end

  def client
    @client ||= Faye::Client.new(websocket_url)
  end

  private
    def app
      Rack::Builder.app do
        run App.new
      end
    end

    class App
      def call(env)
        case env["PATH_INFO"]
        when "/"
          user_agent = UserAgent.parse(env["HTTP_USER_AGENT"])
          session = BR::Session.create(user_agent: user_agent)
          [302, { "Location" => "/sessions/#{session.id}" }, []]
        when /sessions\/\w+/
          env["PATH_INFO"] = "/blade/#{BR.config.framework}.html"
          BR::Assets.environment.call(env)
        when Regexp.new(WEBSOCKET_PATH)
          bayeux.call(env)
        else
          BR::Assets.environment.call(env)
        end
      end

      def bayeux
        @bayeux ||= Faye::RackAdapter.new(mount: WEBSOCKET_PATH, timeout: 25)
      end
    end
end
