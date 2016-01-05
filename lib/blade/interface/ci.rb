module Blade::CI
  extend self
  include Blade::Component

  def start
    @completed_sessions = 0
    @failures = []

    Blade.subscribe("/results") do |details|
      process_result(details)
    end
  end

  private
    def process_result(details)
      if status = details[:status]
        STDOUT.print status_dot(status)

        if status == "fail"
          @failures << details
        end
      end

      if details[:completed]
        process_completion
      end
    end

    def process_completion
      @completed_sessions += 1

      if done?
        EM.add_timer 2 do
          display_failures
          STDOUT.puts
          exit_with_status_code
        end
      end
    end

    def status_dot(status)
      Blade::TestResults::STATUS_DOTS[status]
    end

    def done?
      @completed_sessions == (Blade.config.expected_sessions || 1)
    end

    def display_failures
      @failures.each do |details|
        STDERR.puts "\n\n#{status_dot(details[:status])} #{details[:name]} (#{Blade::Session.find(details[:session_id])})"
        STDERR.puts details[:message]
      end
    end

    def exit_with_status_code
      exit @failures.any? ? 1 : 0
    end
end
