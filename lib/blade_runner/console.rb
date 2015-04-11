require "curses"

module BladeRunner
  class Console < Base
    include Curses

    def start
      run
    end

    def stop
      close_screen
    end

    def run
      start_screen
      init_windows
      init_tabs
      handle_keys

      subscribe("/filewatcher") do
        publish("/commands", command: "start")
      end

      subscribe("/tests") do |details|
        draw_tab_status_dots
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
        init_pair(COLOR_WHITE,COLOR_WHITE,COLOR_BLACK)
        @white = color_pair(COLOR_WHITE)

        init_pair(COLOR_YELLOW,COLOR_YELLOW,COLOR_BLACK)
        @yellow = color_pair(COLOR_YELLOW)

        init_pair(COLOR_GREEN,COLOR_GREEN,COLOR_BLACK)
        @green = color_pair(COLOR_GREEN)

        init_pair(COLOR_RED,COLOR_RED,COLOR_BLACK)
        @red = color_pair(COLOR_RED)

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
        runner.browsers.each do |browser|
          @tabs << OpenStruct.new(browser: browser)
        end
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

          width = tab.browser.name.length + 6
          window = @screen.subwin(@tab_height, width, @tab_y, tab_x)

          if tab.active
            inner_width = tab.browser.name.length + 4
            window.addstr "╔" + "═" * inner_width + "╗"
            window.addstr "║"
            window.addstr("   ")
            window.attron(A_BOLD)
            window.addstr tab.browser.name
            window.attroff(A_BOLD)
            window.addstr(" ")
            window.addstr                           "║"
            window.addstr "╝" + " " * inner_width + "╚"
          else
            window.addstr "\n"
            window.addstr "    "
            window.addstr tab.browser.name
            window.addstr "  "
            window.addstr "═" * width
          end

          window.refresh
          tab.window = window
          tab_x += width
        end

        draw_tab_status_dots
      end

      def draw_tab_status_dots
        @tabs.each do |tab|
          if tab.status_window
            tab.status_window.clear
            tab.status_window.close
          end

          x = tab.window.begx + 2
          y = tab.window.begy + 1
          tab.status_window = Window.new(1,1,y,x)

          color = if tab.browser.test_results.failures.any?
            @red
          else
            if tab.browser.test_results.status == "running"
              @yellow
            elsif tab.browser.test_results.status == "finished"
              @green
            end
          end

          bullet = tab.browser.test_results.status == "pending" ? "○" : "●"

          tab.status_window.attrset(color) if color
          tab.status_window.addstr(bullet)
          tab.status_window.refresh
        end
      end

      def display_tab(tab)
        @tabs.each { |t| t.active = false }
        tab.active = true
        draw_tabs

        @results_window.clear
        @results_window.addstr(tab.browser.test_results.to_s)
        @results_window.refresh
      end
  end
end
