require "curses"

class BladeRunner::Console
  include BladeRunner::Knife
  include Curses

  def start
    run
    assets.watch_test_scripts_for_changes
  end

  def stop
    close_screen
  end

  def run
    @tabs = []

    start_screen
    init_windows
    handle_keys

    subscribe("/results") do |details|
      session = sessions[details["session_id"]]

      if @active_tab && @active_tab.session_id == session.id
        if line = details["line"]
          @results_window.addstr(line + "\n")
          @results_window.refresh
        end
      else
        unless @tabs.detect { |t| t.session_id == session.id }
          name = "#{session} (#{session.id})"
          tab = OpenStruct.new(session_id: session.id, name: name)
          @tabs << tab
          activate_tab(@tabs.first) if @tabs.size == 1
        end
      end

      EM.next_tick { draw_tabs }
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
      header_height = 3
      @header_window = @screen.subwin(header_height, 0, y, 1)
      @header_window.attron(A_BOLD)
      @header_window.addstr "BLADE RUNNER [press 'q' to quit]\n"
      @header_window.attroff(A_BOLD)
      @header_window.addstr "Open #{blade_url} to start"
      @header_window.refresh
      y += header_height

      @tab_height = 3
      @tab_y = y
      y += @tab_height + 1

      status_height = 1
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
        tab.status = sessions[tab.session_id].test_results.status

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

      @screen.refresh
    end

    def tabs_need_redraw?
      if @tabs.any?
        (@active_tab.nil? || @active_tab != @tabs.detect(&:active)) ||
          @tabs.any? { |tab| tab.status != sessions[tab.session_id].test_results.status }
      end
    end

    def activate_tab(tab)
      @tabs.each { |t| t.active = false }
      tab.active = true
      draw_tabs
      @active_tab = tab

      @status_window.clear
      @status_window.addstr(tab.name)
      @status_window.refresh

      @results_window.clear
      @results_window.addstr(sessions[tab.session_id].test_results.to_s)
      @results_window.refresh
    end

    def color_for_status(status)
      case status
      when "running"  then @yellow
      when "finished" then @green
      when /fail/     then @red
      end
    end
end
