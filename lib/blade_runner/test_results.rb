class BladeRunner
  class TestResults < Base
    attr_reader :browser
    attr_reader :status

    def initialize(browser)
      @browser = browser
      @runner = browser.runner
      reset

      subscribe("/tests") do |details|
        if details["browser"] == browser.name
          process_test_result(details)
        end
      end
    end

    def reset
      @results = []
      @status = "pending"
      @plan = nil
    end

    def process_test_result(details)
      case details["event"]
      when "begin"
        reset
        @status = "running"
        @plan = details["total"]
      when "result"
        if details["result"]
          @results << { pass: details["name"] }
        else
          @results << { fail: details["name"] }
        end
      when "end"
        @status = "finished"
      end
    end

    def failures
      @results.select { |r| r[:fail] }
    end

    def to_s
      to_tap
    end

    def to_tap
      lines = []
      lines << "1..#{@plan}}" if @plan

      @results.each_with_index do |result, index|
        if result[:pass]
          lines << "ok #{index + 1} #{result[:pass]}"
        else
          lines << "not ok #{index + 1} #{result[:pass]}"
        end
      end

      lines.join("\n")
    end
  end
end
