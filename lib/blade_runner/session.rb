class BladeRunner::Session < BladeRunner::Model
  class << self
    def create(attributes)
      model = super
      model.test_results = BladeRunner::TestResults.new(model.id)
      model
    end

    def combined_test_results
      BladeRunner::CombinedTestResults.new(all)
    end
  end

  def to_s
    @to_s ||= "#{ua.browser} #{ua.version} #{ua.platform}"
  end

  private
    def ua
      user_agent
    end
end
