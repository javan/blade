require "eventmachine"
require "curses"

class BladeRunner
  class Console < Base
    def start
      run
    end

    def run
      EM.run do
        init_screen
        init_windows

        flash("Starting...")

        subscribe("/tests") do |details|
          process_test_result(details)
        end

        subscribe("/filewatcher") do
          flash("Restarting...")
          publish("/commands", command: "start")
        end
      end
    end

    private
      def init_screen
        Curses.init_screen
        Curses.refresh
        @screen = Curses.stdscr
      end

      def init_windows
        @windows = {}
        @y = 0
        @x = 1
        @height = 6

        @windows["console"] = @screen.subwin(2, 0, @y, @x)
        @y += 2

        runner.browsers.each do |browser|
          @screen.setpos(@y, 1)
          @y += 1
          @screen.addstr(browser.name + "\n")

          subwin = @screen.subwin(@height, 0, @y, @x)
          @y += @height
          subwin.scrollok(true)
          @windows[browser.name] = subwin
        end

        @screen.refresh
      end

      def process_test_result(details)
        details = OpenStruct.new(details)
        window = @windows[details.browser]

        case details.event
        when "begin"
          window.addstr "1..#{details.total}\n"
          window.addstr "# Broswer: #{details.browser}\n"
        when "result"
          if details.result
            window.addstr "ok #{details.number} #{details.name}\n"
          else
            window.addstr "ok #{details.number} #{details.name}\n"
          end
        when "end"
          window.addstr "# Test completed in #{details.runtime} milliseconds.\n"
          window.addstr "# #{details.passed} assertions of #{details.total} passed, #{details.failed} failed.\n"
        end

        window.refresh
      end

      def flash(message)
        window = @windows["console"]
        window.clear
        window.addstr(message)
        window.refresh

        EM.add_timer(2) do
          window.clear
          window.refresh
        end
      end
  end
end
