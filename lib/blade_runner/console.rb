require "eventmachine"
require "curses"

class BladeRunner
  class Console < Base
    include Curses

    def start
      run
    end

    def run
      EM.run do
        start_screen
        init_windows
        EM.defer { handle_keys }

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
        @tabs = {}

        init_pair(COLOR_GREEN,COLOR_GREEN,COLOR_BLACK)
        @green = color_pair(COLOR_GREEN)

        @y = 0
        @x = 1

        console_height = 2
        @console = @screen.subwin(console_height, 0, @y, @x)
        @y += console_height

        @tab_height = 4
        @tab_y = @y
        @tab_x = @x
        @y += @tab_height

        results_height = 20
        @results_window = @screen.subwin(results_height, 0, @y, @x)
        @results_window.scrollok(true)
        @y += results_height

        @screen.refresh
      end

      def handle_keys
        while ch = getch
          case ch
          when KEY_LEFT
            nil
          when KEY_RIGHT
            if @tabs.size > 1
              active_index = 0
              @tabs.each_with_index do |(name, tab), index|
                if tab.active
                  active_index = index
                end
              end

              if active_index < @tabs.size - 1
                display_tab(@tabs.keys[active_index + 1])
              else
                display_tab(@tabs.keys[0])
              end
            end
          else
            flash("key: #{ch}")
          end
        end
      end

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

      def find_or_create_tab(name)
        if @tabs[name]
          @tabs[name]
        else
          @tabs[name] = OpenStruct.new(content: "")
          if @tabs.size == 1
            display_tab(name)
          else
            draw_tabs
          end
          @tabs[name]
        end
      end

      def draw_tabs
        tab_x = @tab_x

        @tabs.each do |name, tab|
          if tab.window
            tab.window.clear
            tab.window.close
          end

          width = name.length + 4
          window = @screen.subwin(@tab_height, width, @tab_y, tab_x)

          if tab.active
            inner_width = name.length + 2
            window.addstr "╔" + "═" * inner_width + "╗"
            window.addstr "║"
            window.attron(@green)
            window.addstr(" #{name} ")
            window.attroff(@green)
            window.addstr                           "║"
            window.addstr "╝" + " " * inner_width + "╚"
          else
            window.addstr "\n"
            window.addstr "  #{name}  "
            window.addstr "═" * width
          end

          window.refresh
          tab.window = window
          tab_x += width
        end
      end

      def display_tab(name)
        flash(name)

        tab = @tabs[name]
        @tabs.values.each { |t| t.active = false }
        tab.active = true
        draw_tabs

        @results_window.clear
        @results_window.addstr(tab.content)
        @results_window.refresh
      end

      def flash(message)
        @console.clear
        @console.addstr(message)
        @console.refresh

        EM.add_timer(2) do
          @console.clear
          @console.refresh
        end
      end
  end
end
