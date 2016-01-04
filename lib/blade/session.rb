class Blade::Session < Blade::Model
  KEY = "blade_session"

  class << self
    def create(attributes)
      model = super
      model.test_results = Blade::TestResults.new(model.id)
      model
    end

    def combined_test_results
      Blade::CombinedTestResults.new(all)
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
