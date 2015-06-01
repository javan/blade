class Blade
  FAYE_URL: "http://localhost:#{window.location.port}/faye"
  CHANNEL: "/tests"
  SESSION_ID: window.location.pathname.match(/sessions\/(\w+)/)?[1]

  constructor: ->
    @client = new Faye.Client @FAYE_URL
    @client.subscribe "/assets", (data) ->
      window.location.reload() if data.changed

  publish: (event, data = {}) ->
    data = copy(data)
    data.event = event
    data.session_id = @SESSION_ID
    @client.publish(@CHANNEL, data)

  copy = (object) ->
    results = {}
    results[key] = value for key, value of object
    results

@blade = new Blade
