require "blade_runner"
require "minitest/autorun"

ActiveSupport.test_order = :random

class BladeRunner::TestCase < ActiveSupport::TestCase
end
