class Blade::RackAdapter
  include Blade::RackRouter

  route "", to: :redirect_to_index
  route "/", to: :index
  route "/blade/websocket*", to: :websocket
  default_route to: :environment

  attr_reader :request, :env

  def initialize
    Blade.initialize!
  end

  def call(env)
    @env = env
    @request = Rack::Request.new(env)

    route = find_route(request.path_info)
    base_path, action = route.values_at(:base_path, :action)

    rewrite_path!(base_path)

    send(action[:to])
  end

  def index
    request.path_info = "/blade/index.html"
    response = environment
    response = add_session_cookie(response) if needs_session_cookie?
    response.to_a
  end

  def redirect_to_index
    Rack::Response.new.tap do |response|
      path = request.path
      path = path + "/" unless path.last == "/"
      response.redirect(path)
    end.to_a
  end

  def websocket
    faye_adapter.call(env)
  end

  def environment
    Blade::Assets.environment.call(env)
  end

  private
    def needs_session_cookie?
      Blade.running? && !Blade::Session.find(request.cookies[Blade::Session::KEY])
    end

    def add_session_cookie(response)
      user_agent = UserAgent.parse(request.user_agent)
      session = Blade::Session.create(user_agent: user_agent)
      status, headers, body = response
      response = Rack::Response.new(body, status, headers)
      response.set_cookie(Blade::Session::KEY, session.id)
      response
    end

    def rewrite_path!(path = nil)
      return if path.nil?
      request.path_info = request.path_info.sub(path, "").presence || "/"
      request.script_name = request.script_name + path
    end

    def faye_adapter
      @faye_adapter ||= Faye::RackAdapter.new(mount: "/", timeout: 25)
    end
end
