require "securerandom"

class BladeRunner::SessionManager
  class Session < OpenStruct
    def to_s
      @to_s ||= "#{ua.browser} #{ua.version} #{ua.platform}"
    end

    private
      def ua
        user_agent
      end
  end

  def initialize
    @sessions = {}
  end

  def create(user_agent)
    id = SecureRandom.hex(4)
    test_results = BladeRunner::TestResults.new(id)
    @sessions[id] = Session.new(id: id, test_results: test_results, user_agent: user_agent)
  end

  def [](id)
    @sessions[id]
  end

  def all
    @sessions.values
  end

  def size
    @sessions.size
  end

  def combined_test_results
    BladeRunner::CombinedTestResults.new(all)
  end
end
