require "eventmachine"
require "curses"

class BladeRunner
  class Console < Base
    def start
      @top = 1
      @height = 12
      @window = screen

      run
    end

    def screen
      Curses.init_screen
      Curses.refresh
      Curses.stdscr
    end

    def run
      EM.run do
        subscribe("/tests") do |details|
          process_test_result(details)
        end

        subscribe("/filewatcher") do
          publish("/commands", command: "start")
        end
      end
    end

    private
      def process_test_result(details)
        details = OpenStruct.new(details)
        tap = TapStream.for(details.browser)

        case details.event
        when "begin"
          tap.plan details.total
          tap.comment "Broswer: #{details.browser}"
          consume_tap_stream(tap)
        when "result"
          if details.result
            tap.pass details.number, details.name
          else
            tap.fail details.number, details.name
          end
        when "end"
          tap.comment "Test completed in #{details.runtime} milliseconds."
          tap.comment "#{details.passed} assertions of #{details.total} passed, #{details.failed} failed."
          tap.done
        end
      end

      def consume_tap_stream(stream)
        EM.defer do
          window = @window.subwin(@height, 0, @top, 1)
          @top += @height + 1
          window.scrollok(true)
          while line = stream.gets
            window.addstr(line)
            window.refresh
          end
          stream.close
        end
      end
  end
end
