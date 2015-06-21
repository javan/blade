module BladeRunner::TemplateHelper
  def blade_runner_head
    [].tap do |html|
      html << %Q(<meta name="websocket" content="#{BR::Server.websocket_url}">)
      html << %Q(<script src="/blade.js"></script>)

      if asset = BR::Assets.environment['_test_head.html']
        html << asset.to_s
      end
    end.join("\n")
  end

  def blade_runner_body
    [].tap do |html|
      BR::Assets.logical_paths(:js).each do |path|
        html << %Q(<script src="/#{path}"></script>)
      end

      if asset = BR::Assets.environment['_test_body.html']
        html << asset.to_s
      end
    end.join("\n")
  end
end
