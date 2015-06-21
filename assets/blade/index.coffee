#= require faye-browser

class Blade
  CHANNEL: "/tests"
  SESSION_ID: window.location.pathname.match(/sessions\/(\w+)/)?[1]

  constructor: ->
    @client = new Faye.Client getMetaTagContent("websocket")
    @client.subscribe "/assets", (data) ->
      window.location.reload() if data.changed

    setInterval =>
      @client.publish("/browsers", message: "ping", session_id: @SESSION_ID)
    , 1000

  publish: (event, data = {}) ->
    data = copy(data)
    data.event = event
    data.session_id = @SESSION_ID
    @client.publish(@CHANNEL, data)

  copy = (object) ->
    results = {}
    results[key] = value for key, value of object
    results

  getMetaTagContent = (name) ->
    document.querySelector("meta[name='#{name}']").getAttribute("content")

@blade = new Blade
