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


subscribe ({command} = {}) ->
  switch command
    when "start"
      window.location.reload()

QUnit.config.hidepassed = true
QUnit.config.testTimeout = 5000

log = []
testName = null

QUnit.begin (details) ->
  publish("begin", total: details.totalTests)

QUnit.testStart (testDetails) ->
  QUnit.log (details) ->
    if !details.result
      details.name = testDetails.name
      log.push details

QUnit.testDone (details) ->
  result = details.failed is 0
  name = "#{details.module}: #{details.name}"
  publish("result", {result, name})

QUnit.done (test_results) ->
  tests = []
  i = 0
  len = log.length
  while i < len
    details = log[i]
    tests.push
      name: details.name
      result: details.result
      expected: details.expected
      actual: details.actual
      source: details.source
    i++
  test_results.tests = tests
  window.global_test_results = test_results

  publish("end", test_results)
