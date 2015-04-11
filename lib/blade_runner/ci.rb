class BladeRunner
  class CI < Base
    def start
      @finished_count = 0
      @browser_count = runner.browsers.size

      print "# Running"

      subscribe("/results") do |details|
        if details["event"] == "finished"
          @finished_count += 1
        end

        if @finished_count == @browser_count
          puts
          puts TestResults::Combiner.new(runner.browsers.map(&:test_results)).to_tap
          exit(fail? ? 1 : 0)
        elsif details.has_key?("result")
          if details["result"]
            print "."
          else
            print "F"
          end
        end
      end
    end

    def stop
    end

    private
      def fail?
        runner.browsers.map(&:test_results).any? { |r| r.failures.any? }
      end
  end
end
