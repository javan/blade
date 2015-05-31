require "faye/websocket"

class BladeRunner::Server
  include BladeRunner::Knife

  def start
    Faye::WebSocket.load_adapter("thin")
    Rack::Server.start(app: app, Port: config.port, server: "thin")
  end

  private
    class App
      include BladeRunner::Knife

      def call(env)
        case env["PATH_INFO"]
        when "/"
          [302, { "Location" => "/sessions/#{sessions.create.id}" }, []]
        when /sessions\/\w+/
          env["PATH_INFO"] = "/blade/#{config.framework}.html"
          assets.environment.call(env)
        when /faye/
          BladeRunner.bayeux.call(env)
        else
          assets.environment.call(env)
        end
      end
    end

    def app
      Rack::Builder.app do
        run App.new
      end
    end
end
