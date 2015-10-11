class Blade::CombinedTestResults
  attr_reader :sessions, :all_test_results

  def initialize(sessions)
    @sessions = sessions
    @all_test_results = sessions.map(&:test_results)
  end

  def total
    sum(totals)
  end

  def lines(type = :results)
    sessions.flat_map do |session|
      session.test_results.send(type).map do |line|
        line.sub(/ok/, "ok [#{session}]")
      end
    end
  end

  def to_s
    lines = ["1..#{total}"] + lines(:failures) + lines(:passes)
    lines.join("\n")
  end

  def failed?
    states.include?("failed")
  end

  private
    def sum(values)
      values.inject(0) { |sum, total| sum + total }
    end

    def totals
      all_test_results.map(&:total).compact
    end

    def states
      all_test_results.map(&:state)
    end
end
