module BladeRunner::CI
  extend self
  include BladeRunner::Component

  def start
    @completed_sessions = 0

    log "# Running"
    BR.subscribe("/results") do |details|
      process_result(details)
    end
  end

  private
    def process_result(details)
      if details.has_key?("pass")
        log details["pass"] ? "." : "F"
      end

      if details["completed"]
        process_completion
      end
    end

    def process_completion
      @completed_sessions += 1

      if done?
        log "\n"
        display_results_and_exit
      end
    end

    def done?
      @completed_sessions == (BR.config.expected_sessions || 1)
    end

    def display_results_and_exit
      results = BR::Session.combined_test_results
      display results
      exit results.failed? ? 1 : 0
    end

    def log(message)
      STDERR.print message.to_s
    end

    def display(message)
      STDOUT.puts message.to_s
    end
end
