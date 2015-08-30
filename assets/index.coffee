@Blade =
  suiteDidBegin: (details) ->
    publish("/tests", event: "begin", total: details.total)

  testDidEnd: (details) ->
    publish("/tests", event: "result", result: details.pass, name: details.name, message: details.message)

  suiteDidEnd: (details) ->
    publish("/tests", event: "end", total: details.total)

publish = (channel, data = {}) ->
  client.publish(channel, copy(data, {session_id})) if session_id?

copy = (object, withAttributes = {}) ->
  result = {}
  result[key] = value for key, value of object
  result[key] = value for key, value of withAttributes
  result

getWebSocketURL = ->
  element = document.querySelector("script[data-websocket]")
  element.src.replace(/\/client\.js$/, "")

getSessionId = ->
  document.cookie.match(/blade_session=(\w+)/)?[1]

client = new Faye.Client(getWebSocketURL())

if session_id = getSessionId()
  client.subscribe "/assets", (data) ->
    location.reload() if data.changed

  setInterval ->
    publish("/browsers", event: "ping")
  , 1000
