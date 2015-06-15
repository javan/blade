require "curses"

class BladeRunner::Console
  include BladeRunner::Knife
  include Curses

  COLOR_NAMES = %w( white yellow green red )

  def self.colors
    @colors ||= OpenStruct.new.tap do |colors|
      COLOR_NAMES.each do |name|
        const = Curses.const_get("COLOR_#{name.upcase}")
        Curses.init_pair(const, const, Curses::COLOR_BLACK)
        colors[name] = Curses.color_pair(const)
      end
    end
  end

  class Tab < OpenStruct
    extend Forwardable
    def_delegators "BladeRunner::Console", :colors

    @tabs = {}

    class << self
      attr_accessor :tabs
      attr_reader :window

      def init_windows(parent_window, height, width, top, left)
        @top = top
        @left = left
        @window = parent_window.subwin(height, width, top, left)
      end

      def draw
        window.clear
        window.noutrefresh

        all.each_with_index do |tab, index|
          left = index * 5 + @left
          tab.window.move(@top, left)
          tab.draw
        end
      end

      def create(attributes)
        left = size * 5 + @left
        tab_window = window.subwin(3, 5, @top, left)
        tabs[attributes[:id]] = new attributes, tab_window
      end

      def remove(id)
        find(id).window.close
        tabs.delete(id)
        draw
      end

      def find(id)
        tabs[id]
      end

      def activate(id)
        all.each do |tab|
          tab.active = (tab.id == id)
          tab.draw
        end
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
        threshold = Time.now - 2
        all.select { |t| t.last_ping_at && t.last_ping_at < threshold }
      end
    end

    attr_reader :window

    def initialize(attributes, window)
      super(attributes)
      @window = window
      draw
    end

    def draw
      window.clear
      active? ? draw_active : draw_inactive
      window.noutrefresh
    end

    def draw_active
      window.addstr "╔═══╗"
      window.addstr "║ "
      window.attron(color)
      window.addstr(dot)
      window.attroff(color)
      window.addstr(" ║")
      window.addstr "╝   ╚"
    end

    def draw_inactive
      window.addstr "\n"
      window.attron(color)
      window.addstr("  #{dot}\n")
      window.attroff(color)
      window.addstr "═════"
    end

    def dot
      status == "pending" ? "○" : "●"
    end

    def active?
      active
    end

    def status
      BladeRunner.sessions[id].test_results.status
    end

    def color
      case status
      when "running"  then colors.yellow
      when "finished" then colors.green
      when /fail/     then colors.red
      else                 colors.white
      end
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
          @results_window.noutrefresh
        end
      else
        tab = Tab.create(id: session.id, name: "#{session} (#{session.id})")
        activate_tab(tab) if Tab.size == 1
      end

      tab.draw
      doupdate
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
    end

    def init_windows
      y = 0
      header_height = 3
      @header_window = @screen.subwin(header_height, 0, y, 1)
      @header_window.attron(A_BOLD)
      @header_window.addstr "BLADE RUNNER [press 'q' to quit]\n"
      @header_window.attroff(A_BOLD)
      @header_window.addstr "Open #{blade_url} to start"
      @header_window.noutrefresh
      y += header_height

      @tab_height = 3
      @tab_y = y

      Tab.init_windows(@screen, @tab_height, 0, @tab_y, 1)
      y += @tab_height + 1

      status_height = 1
      @status_window = @screen.subwin(status_height, 0, y, 1)
      y += status_height + 1

      results_height = @screen.maxy - y
      @results_window = @screen.subwin(results_height, 0, y, 1)
      @results_window.scrollok(true)

      doupdate
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

    def activate_tab(tab)
      Tab.activate(tab.id)

      @status_window.clear
      @status_window.addstr(tab.name)
      @status_window.noutrefresh

      @results_window.clear
      @results_window.addstr(sessions[tab.id].test_results.to_s)
      @results_window.noutrefresh

      doupdate
    end

    def remove_tab(tab)
      Tab.remove(tab.id)

      if tab.active?
        @status_window.clear
        @status_window.noutrefresh

        @results_window.clear
        @results_window.noutrefresh
      end

      doupdate
    end
end
