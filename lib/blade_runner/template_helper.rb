module BladeRunner::TemplateHelper
  def blade_runner_head
    html = []
    html << %Q(<meta name="websocket" content="#{BR::Server.websocket_url}">)
    html << %Q(<script src="/blade.js"></script>)
    html.join("\n")
  end

  def blade_runner_body
    html = []
    BR::Assets.logical_paths(:js).each do |path|
      html << %Q(<script src="/#{path}"></script>)
    end
    html.join("\n")
  end
end
