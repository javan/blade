require "curses"

class BladeRunner::Console
  include BladeRunner::Knife
  include Curses

  def start
    run
  end

  def stop
    close_screen
  end

  def run
    @tabs = []
    @sessions = {}

    start_screen
    init_windows
    handle_keys

    subscribe("/tests") do |details|
      if session_id = details["session_id"]
        if @sessions[session_id].nil?
          session = OpenStruct.new(browser: details["browser"], test_results: BladeRunner::TestResults.new(session_id))
          @sessions[session_id] = session
          tab = OpenStruct.new(session_id: session_id, name: "#{details["browser"]} (#{session_id})")
          @tabs << tab
          activate_tab(@tabs.first) if @tabs.size == 1
        end
      end

      draw_tabs

      if details["result"]
        if @active_tab.session_id == details["session_id"]
          test_results = @sessions[@active_tab.session_id].test_results
          if result = test_results.results.last
            @results_window.addstr(result.to_tap + "\n")
            @results_window.refresh
          end
        end
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
      init_pair(COLOR_WHITE,COLOR_WHITE,COLOR_BLACK)
      @white = color_pair(COLOR_WHITE)

      init_pair(COLOR_YELLOW,COLOR_YELLOW,COLOR_BLACK)
      @yellow = color_pair(COLOR_YELLOW)

      init_pair(COLOR_GREEN,COLOR_GREEN,COLOR_BLACK)
      @green = color_pair(COLOR_GREEN)

      init_pair(COLOR_RED,COLOR_RED,COLOR_BLACK)
      @red = color_pair(COLOR_RED)

      y = 0
      header_height = 2
      @header_window = @screen.subwin(header_height, 0, y, 1)
      @header_window.attron(A_BOLD)
      @header_window.addstr "BLADE RUNNER [press 'q' to quit]\n"
      @header_window.attroff(A_BOLD)
      @header_window.addstr "Open #{test_url} to start"
      @header_window.refresh
      y += header_height

      @tab_height = 3
      @tab_y = y
      y += @tab_height + 1

      status_height = 2
      @status_window = @screen.subwin(status_height, 0, y, 1)
      y += status_height + 1

      results_height = @screen.maxy - y
      @results_window = @screen.subwin(results_height, 0, y, 1)
      @results_window.scrollok(true)

      @screen.refresh
    end

    def handle_keys
      EM.defer do
        while ch = getch
          case ch
          when KEY_LEFT
            change_tab(:previous)
          when KEY_RIGHT
            change_tab(:next)
          when "q"
            BladeRunner.stop
          end
        end
      end
    end

    def change_tab(direction = :next)
      index = @tabs.index(@tabs.detect(&:active))
      tabs = @tabs.rotate(index)
      tab = direction == :next ? tabs[1] : tabs.last
      activate_tab(tab)
    end

    def draw_tabs
      return unless tabs_need_redraw?

      # Horizontal line
      @screen.setpos(@tab_y + 2, 0)
      @screen.addstr("═" * @screen.maxx)

      tab_x = 1
      @tabs.each do |tab|
        tab.status = @sessions[tab.session_id].test_results.status

        if tab.window
          tab.window.clear rescue nil
          tab.window.close
          tab.window = nil
        end

        width = 5
        window = @screen.subwin(@tab_height, width, @tab_y, tab_x)
        tab.window = window

        dot = tab.status == "pending" ? "○" : "●"
        color = color_for_status(tab.status)

        if tab.active
          window.addstr "╔═══╗"
          window.addstr "║ "
          window.attron(color) if color
          window.addstr(dot)
          window.attroff(color) if color
          window.addstr(" ║")
          window.addstr "╝   ╚"
        else
          window.addstr "\n"
          window.attron(color) if color
          window.addstr("  #{dot}\n")
          window.attroff(color) if color
          window.addstr "═════"
        end

        window.refresh
        tab_x += width
      end
    end

    def tabs_need_redraw?
      @active_tab.nil? ||
        (@active_tab != @tabs.detect(&:active)) ||
        @tabs.any? { |tab| tab.window.nil? || tab.status != @sessions[tab.session_id].test_results.status }
    end

    def activate_tab(tab)
      @tabs.each { |t| t.active = false }
      tab.active = true
      draw_tabs
      @active_tab = tab

      @status_window.clear
      @status_window.addstr(tab.name + "\n")
      @status_window.addstr(tab.status)
      @status_window.refresh

      @results_window.clear
      @results_window.addstr(@sessions[tab.session_id].test_results.to_tap)
      @results_window.refresh
    end

    def color_for_status(status)
      case status
      when "running"  then @yellow
      when "finished" then @green
      when "failed"   then @red
      end
    end
end
