fayeURL = "http://localhost:#{window.location.port}/faye"
client = new Faye.Client fayeURL
channel = "/tests"

@subscribe = (callback) ->
  client.subscribe("/commands", callback)

@publish = (event, data = {}) ->
  data = copy(data)
  data.browser = getParams().browser
  data.event = event
  client.publish(channel, data)

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


subscribe ({command} = {}) ->
  switch command
    when "start"
      window.location.reload()


