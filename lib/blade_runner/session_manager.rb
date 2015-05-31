require "securerandom"

class BladeRunner::SessionManager
  def initialize
    @sessions = {}
  end

  def create
    id = SecureRandom.hex(4)
    session = OpenStruct.new(id: id, test_results: BladeRunner::TestResults.new(id))
    @sessions[id] = session
  end

  def [](id)
    @sessions[id]
  end

  def size
    @sessions.size
  end
end
