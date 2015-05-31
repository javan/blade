#= require ./bowser

class Blade
  FAYE_URL: "http://localhost:#{window.location.port}/faye"
  CHANNEL: "/tests"
  SESSION_KEY: "blade:session"

  constructor: ->
    @client = new Faye.Client @FAYE_URL
    @client.subscribe "/assets", (data) ->
      window.location.reload() if data.changed

  publish: (event, data = {}) ->
    data = copy(data)
    data.event = event
    data.session_id = @getSessionId()
    data.browser = "#{bowser.name} #{bowser.version}"
    @client.publish(@CHANNEL, data)

  getSessionId: ->
    if id = sessionStorage.getItem(@SESSION_KEY)
      id
    else
      id = createRandomKey()
      sessionStorage.setItem(@SESSION_KEY, id)
      id

  createRandomKey = ->
    Math.floor((1 + Math.random()) * 0x100000000).toString(16)

  copy = (object) ->
    results = {}
    results[key] = value for key, value of object
    results

  getParams = ->
    query = location.search.split("?")
    query = query[query.length - 1]

    params = {}
    for pair in query.split("&")
      [key, value] = pair.split("=")
      params[decodeURIComponent(key)] = decodeURIComponent(value)
    params

@blade = new Blade
