require "test_helper"

class BladeTest < Blade::TestCase
  test "initialize" do
    assert Blade.initialize!
  end
end
