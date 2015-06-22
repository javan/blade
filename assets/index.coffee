#= require faye-browser

websocketURL = document.querySelector("meta[name=websocket]").getAttribute("content")
@client = new Faye.Client websocketURL
session_id = document.cookie.match(/blade_runner_session=(\w+)/)?[1]

publish = ({channel, event, data}) ->
  if session_id?
    data = extend(copy(data), {event, session_id})
    client.publish(channel, data)

copy = (object) ->
  results = {}
  results[key] = value for key, value of object
  results

extend = (object, attributes) ->
  object[key] = value for key, value of attributes
  object

if session_id?
  client.subscribe "/assets", (data) ->
    location.reload() if data.changed

  setInterval ->
    publish(channel: "/browsers", event: "ping")
  , 1000

@BladeRunner =
  suiteBegin: ({total}) ->
    publish("/tests", event: "begin", data: {total})

  testResult: ({name, pass, message}) ->
    result = pass
    publish(channel: "/tests", event: "result", data: {result, name, message})

  suiteEnd: (details) ->
    publish(channel: "/tests", event: "end", data: details)
