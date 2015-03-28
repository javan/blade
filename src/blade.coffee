fayeURL = "http://localhost:#{window.location.port}/faye"
client = new Faye.Client fayeURL
channel = "/tests"

subscribe = (callback) ->
  client.subscribe("/commands", callback)

publish = (event, data = {}) ->
  data.browser = getParams().browser
  data.event = event
  client.publish(channel, data)

getParams = ->
  query = location.search.split("?")
  query = query[query.length - 1]

  params = {}
  for pair in query.split("&")
    [key, value] = pair.split("=")
    params[decodeURIComponent(key)] = decodeURIComponent(value)
  params

testNumber = null

QUnit.begin (details) ->
  testNumber = 1
  publish("begin", total: details.totalTests)

QUnit.testDone (details) ->
  result = details.failed is 0
  name = "#{details.module}: #{details.name}"
  number = testNumber++
  publish("result", {result, name, number})

QUnit.done (details) ->
  publish("end", details)


subscribe ({command} = {}) ->
  switch command
    when "start"
      window.location.reload()
