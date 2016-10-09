@Blade =
  suiteDidBegin: ({total}) ->
    event = "begin"
    publish("/tests", {event, total})

  testDidEnd: ({name, status, message}) ->
    event = "result"
    publish("/tests", {event, name, status, message})

  suiteDidEnd: ({total}) ->
    event = "end"
    publish("/tests", {event, total})

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
