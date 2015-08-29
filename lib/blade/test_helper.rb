require "blade"
require "minitest/autorun"

ActiveSupport.test_order = :random

class Blade::TestCase < ActiveSupport::TestCase
end
