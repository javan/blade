#= require ./vendor/qunit

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
