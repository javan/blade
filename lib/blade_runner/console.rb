require "eventmachine"
require "curses"

class BladeRunner
  class Console < Base
    include Curses

    def start
      run
    end

    def stop
      close_screen
      EM.stop_event_loop
    end

    def run
      EM.run do
        start_screen
        init_windows
        init_tabs
        handle_keys

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
        results = ""

        case details.event
        when "begin"
          results << "1..#{details.total}\n"
          results << "# Broswer: #{details.browser}\n"
        when "result"
          if details.result
            results << "ok #{details.number} #{details.name}\n"
          else
            results << "ok #{details.number} #{details.name}\n"
          end
        when "end"
          results << "# #{details.browser} tests completed in #{details.runtime} milliseconds.\n"
          results << "# #{details.passed} assertions of #{details.total} passed, #{details.failed} failed.\n"
        end

        tab = find_or_create_tab(details.browser)
        tab.content << results

        if tab.active
          @results_window.addstr results
          @results_window.refresh
        end
      end

      def start_screen
        init_screen
        start_color
        noecho
        curs_set(0)
        @screen = stdscr
        @screen.keypad(true)
        refresh
      end

      def init_windows
        init_pair(COLOR_GREEN,COLOR_GREEN,COLOR_BLACK)
        @green = color_pair(COLOR_GREEN)

        y = 0
        console_height = 2
        @console = @screen.subwin(console_height, 0, y, 0)
        y += console_height

        @tab_height = 4
        @tab_y = y
        y += @tab_height

        results_height = @screen.maxy - y
        @results_window = @screen.subwin(results_height, 0, y, 1)
        @results_window.scrollok(true)

        @screen.refresh
      end

      def init_tabs
        @tabs = []
        runner.browsers.map(&:name).each { |n| create_tab(n) }
        display_tab(@tabs.first) if @tabs.first
      end

      def handle_keys
        EM.defer do
          while ch = getch
            case ch
            when KEY_LEFT
              change_tab(:previous)
            when KEY_RIGHT
              change_tab(:next)
            end
          end
        end
      end

      def change_tab(direction = :next)
        index = @tabs.index(@tabs.detect(&:active))
        tabs = @tabs.rotate(index)
        tab = direction == :next ? tabs[1] : tabs.last
        display_tab(tab)
      end

      def find_or_create_tab(name)
        if tab = find_tab(name)
          tab
        else
          tab = create_tab(name)
          draw_tabs
          tab
        end
      end

      def find_tab(name)
        @tabs.detect { |t| t.name == name }
      end

      def create_tab(name)
        tab = OpenStruct.new(name: name, content: "")
        @tabs.push(tab)
        tab
      end

      def draw_tabs
        # Horizontal line
        @screen.setpos(@tab_y + 2, 0)
        @screen.addstr("═" * @screen.maxx)
        @screen.refresh

        tab_x = 1
        @tabs.each do |tab|
          if tab.window
            tab.window.clear
            tab.window.close
          end

          width = tab.name.length + 4
          window = @screen.subwin(@tab_height, width, @tab_y, tab_x)

          if tab.active
            inner_width = tab.name.length + 2
            window.addstr "╔" + "═" * inner_width + "╗"
            window.addstr "║"
            window.attron(@green)
            window.addstr(" #{tab.name} ")
            window.attroff(@green)
            window.addstr                           "║"
            window.addstr "╝" + " " * inner_width + "╚"
          else
            window.addstr "\n"
            window.addstr "  #{tab.name}  "
            window.addstr "═" * width
          end

          window.refresh
          tab.window = window
          tab_x += width
        end
      end

      def display_tab(tab)
        @tabs.each { |t| t.active = false }
        tab.active = true
        draw_tabs

        @results_window.clear
        @results_window.addstr(tab.content)
        @results_window.refresh
      end
  end
end
