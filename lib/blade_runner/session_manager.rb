require "securerandom"

class BladeRunner::SessionManager
  def initialize
    @sessions = {}
  end

  def create(attributes = {})
    id = SecureRandom.hex(4)
    test_results = BladeRunner::TestResults.new(id)
    @sessions[id] = OpenStruct.new(attributes.merge(id: id, test_results: test_results))
  end

  def [](id)
    @sessions[id]
  end

  def all
    @sessions
  end

  def size
    @sessions.size
  end
end
