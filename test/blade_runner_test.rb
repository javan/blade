require "blade_runner/test_helper"

class BladeRunnerTest < BladeRunner::TestCase
  test "initialize" do
    assert BladeRunner.initialize!
  end
end
