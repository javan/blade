class BladeRunner::CI
  include BladeRunner::Knife

  def start
    @finished_count = 0

    print "# Running"

    subscribe("/results") do |details|
      if details.has_key?("result")
        if details["result"]
          print "."
        else
          print "F"
        end
      end

      if details["event"] == "finished"
        @finished_count += 1
      end

      if @finished_count == browsers.size
        puts
        puts BladeRunner::TestResults::Combiner.new(browsers.map(&:test_results)).to_tap
        exit(fail? ? 1 : 0)
      end
    end
  end

  def stop
  end

  private
    def fail?
      browsers.map(&:test_results).any? { |r| r.failures.any? }
    end
end
