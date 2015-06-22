class BladeRunner::RackAdapter
  extend Forwardable
  def_delegators "BladeRunner::Assets", :environment

  PATH = "/blade_runner"
  ADAPTER_PATH = PATH + "/adapter"
  WEBSOCKET_PATH = PATH + "/websocket"

  def initialize(app = nil, options = {})
    BR.initialize!

    if app.is_a?(Hash)
      @options = app
    else
      @app, @options = app, options
    end

    @mount_path = @options[:mount]
    @mount_path_pattern = /^#{@mount_path}/

    @blade_runner_path_pattern = /^#{PATH}/
    @adapter_path_pattern = /^#{ADAPTER_PATH}/
    @websocket_path_pattern = /^#{WEBSOCKET_PATH}/
  end

  def call(env)
    unless @mount_path.nil?
      if env["PATH_INFO"] =~ @mount_path_pattern
        env["PATH_INFO"].sub!(@mount_path_pattern, "")
      elsif @app
        return @app.call(env)
      end
    end

    case env["PATH_INFO"]
    when ""
      add_forward_slash(env)
    when "/"
      env["PATH_INFO"] = "index.html"
      response = environment(:blade_runner).call(env)
      response_with_session(response, env)
    when @websocket_path_pattern
      bayeux.call(env)
    when @adapter_path_pattern
      env["PATH_INFO"].sub!(@adapter_path_pattern, "")
      environment(:adapter).call(env)
    when @blade_runner_path_pattern
      env["PATH_INFO"].sub!(@blade_runner_path_pattern, "")
      environment(:blade_runner).call(env)
    else
      environment(:user).call(env)
    end
  end

  private
    def bayeux
      @bayeux ||= Faye::RackAdapter.new(mount: WEBSOCKET_PATH, timeout: 25)
    end

    def add_forward_slash(env)
      path = @mount_path || env["REQUEST_PATH"] || env["SCRIPT_NAME"]
      redirect_to(File.join(path.to_s, "/"))
    end

    def redirect_to(location, status = 301)
      [status, { Location: location }, []]
    end

    def response_with_session(response, env)
      if BR.running?
        user_agent = UserAgent.parse(env["HTTP_USER_AGENT"])
        session = BR::Session.create(user_agent: user_agent)
        status, headers, body = response
        response = Rack::Response.new(body, status, headers)
        response.set_cookie("blade_runner_session", session.id)
        response.finish
      else
        response
      end
    end
end
