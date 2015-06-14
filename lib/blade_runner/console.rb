require "curses"

class BladeRunner::Console
  include BladeRunner::Knife
  include Curses

  class Tab < OpenStruct
    @tabs = {}

    class << self
      attr_accessor :tabs

      def create(attributes)
        tabs[attributes[:id]] = new attributes
      end

      def remove(id)
        tabs.delete(id)
      end

      def find(id)
        tabs[id]
      end

      def all
        tabs.values
      end

      def size
        tabs.size
      end

      def active
        all.detect(&:active?)
      end

      def stale
        stale_threshold = Time.now - 2
        all.select { |t| t.last_ping_at && t.last_ping_at < stale_threshold }
      end
    end

    def active?
      active
    end
  end

  def start
    run
    assets.watch_logical_paths
  end

  def stop
    close_screen
  end

  def run
    start_screen
    init_windows
    handle_keys
    handle_stale_tabs

    subscribe("/results") do |details|
      session = sessions[details["session_id"]]

      if tab = Tab.find(session.id)
        if details["line"] && tab.active?
          @results_window.addstr(details["line"] + "\n")
          @results_window.refresh
        end
      else
        tab = Tab.create(id: session.id, name: "#{session} (#{session.id})")
        activate_tab(tab) if Tab.size == 1
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

    def handle_stale_tabs
      subscribe("/browsers") do |details|
        if details["message"] = "ping"
          if tab = Tab.find(details["session_id"])
            tab.last_ping_at = Time.now
          end
        end
      end

      EM.add_periodic_timer(1) do
        Tab.stale.each { |t| remove_tab(t) }
      end
    end

    def change_tab(direction = :next)
      tabs = Tab.all
      index = tabs.index(Tab.active)
      tabs = tabs.rotate(index)
      tab = direction == :next ? tabs[1] : tabs.last
      activate_tab(tab)
    end

    def draw_tabs(force = false)
      return unless force || tabs_need_redraw?

      # Horizontal line
      @screen.setpos(@tab_y + 2, 0)
      @screen.addstr("═" * @screen.maxx)

      tab_x = 1
      Tab.all.each do |tab|
        tab.status = sessions[tab.id].test_results.status

        if tab.window
          tab.window.clear rescue nil
          tab.window.close rescue nil
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
      if Tab.size > 0
        (@active_tab.nil? || @active_tab != Tab.active) ||
          Tab.all.any? { |tab| tab.status != sessions[tab.id].test_results.status }
      end
    end

    def activate_tab(tab)
      Tab.all.each { |t| t.active = false }
      tab.active = true
      draw_tabs
      @active_tab = tab

      @status_window.clear
      @status_window.addstr(tab.name)
      @status_window.refresh

      @results_window.clear
      @results_window.addstr(sessions[tab.id].test_results.to_s)
      @results_window.refresh
    end

    def remove_tab(tab)
      Tab.remove(tab.id)

      tab.window.clear
      tab.window.close

      if tab == @active_tab
        @status_window.clear
        @status_window.refresh

        @results_window.clear
        @results_window.refresh

        @active_tab = nil
      end

      draw_tabs(:force)
    end

    def color_for_status(status)
      case status
      when "running"  then @yellow
      when "finished" then @green
      when /fail/     then @red
      end
    end
end
