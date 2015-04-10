#= require ./vendor/qunit

QUnit.config.hidepassed = true
QUnit.config.testTimeout = 5000

QUnit.begin (suiteDetails) ->
  publish("begin", total: suiteDetails.totalTests)

failedAssertions = []

QUnit.testStart (testDetails) ->
  failedAssertions = []

QUnit.log (assertionDetails) ->
  unless assertionDetails.result
    failedAssertions.push(assertionDetails)

QUnit.testDone (testDetails) ->
  result = testDetails.failed is 0
  name = "#{testDetails.module}: #{testDetails.name}"
  message = failedAssertions if failedAssertions.length
  publish("result", {result, name, message})

QUnit.done (suiteDetails) ->
  window.global_test_results = suiteDetails
  publish("end", suiteDetails)
