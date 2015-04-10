require "pp"

class BladeRunner
  class TestResults < Base
    attr_reader :browser, :status, :results, :passes, :failures

    def initialize(browser)
      @browser = browser
      super(browser.runner)
      reset

      subscribe("/tests") do |details|
        if details["browser"] == browser.name
          process_test_result(details)
        end
      end
    end

    def reset
      @results, @passes, @failures = [], [], []
      @status = "pending"
      @total = nil
    end

    def process_test_result(details)
      case details["event"]
      when "begin"
        reset
        @status = "running"
        @total = details["total"]
        publish("/results", event: "running")
      when "result"
        klass = details["result"] ? Pass : Failure
        record_result(klass.new("#{browser.name} - #{details["name"]}", details["message"]))
      when "end"
        @status = "finished"
        publish("/results", event: "finished")
      end
    end

    def record_result(result)
      @results << result

      case result
      when Failure
        @failures << result
      when Pass
        @passes << result
      end

      publish("/results", result: result.to_tap)
    end

    def total
      if @total
        @total
      elsif status == "finished"
        results.size
      end
    end

    def to_tap
      lines = results.map(&:to_tap)
      lines = lines.unshift("1..#{total}}") if total
      lines.join("\n")
    end

    class Pass
      def initialize(name, message)
        @name = name
        @message = message
      end

      def to_tap(number = nil)
        ["ok", number, @name, message].compact.join(" ")
      end

      def message
        unless @message.nil?
          "\n" + PP.pp(@message, "").gsub(/^/, "# ").chomp
        end
      end
    end

    class Failure < Pass
      def to_tap(*args)
        "not #{super}"
      end
    end

    class Combiner
      attr_reader :all_test_results

      def initialize(all_test_results)
        @all_test_results = all_test_results
      end

      def total
        totals = all_test_results.map(&:total)
        if totals.all?
          totals.inject(0) { |sum, total| sum + total }
        end
      end

      def sorted_results
        passes, failures = [], []

        all_test_results.each do |test_results|
          passes.push(*test_results.passes)
          failures.push(*test_results.failures)
        end

        passes + failures
      end

      def to_tap
        lines = []

        sorted_results.each_with_index do |result, index|
          lines << result.to_tap(index + 1)
        end

        lines = lines.unshift("1..#{total}") if total
        lines.join("\n")
      end
    end
  end
end
