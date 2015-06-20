require "curses"

module BladeRunner::Console
  extend self
  include BladeRunner::Component

  extend Forwardable
  def_delegators "BladeRunner::Console", :create_window

  COLOR_NAMES = %w( white yellow green red )
  PADDING = 1

  def colors
    @colors ||= OpenStruct.new.tap do |colors|
      COLOR_NAMES.each do |name|
        const = Curses.const_get("COLOR_#{name.upcase}")
        Curses.init_pair(const, const, Curses::COLOR_BLACK)
        colors[name] = Curses.color_pair(const)
      end
    end
  end

  def create_window(options = {})
    height = options[:height] || 0
    width  = options[:width]  || 0
    top    = options[:top]    || 0
    left   = options[:left]   || PADDING
    parent = options[:parent] || Curses.stdscr

    parent.subwin(height, width, top, left)
  end

  class Tab < OpenStruct
    extend Forwardable
    def_delegators "BladeRunner::Console", :colors, :create_window

    @tabs = {}

    class << self
      extend Forwardable
      def_delegators "BladeRunner::Console", :create_window

      attr_accessor :tabs
      attr_reader :window, :status_window, :content_window

      def install(options = {})
        top = options[:top]
        @window = create_window(top: top, height: 3)

        top = @window.begy + @window.maxy + 1
        @status_window = create_window(top: top, height: 1)

        top = @status_window.begy + @status_window.maxy + 1
        @content_window = create_window(top: top)
        @content_window.scrollok(true)
      end

      def draw
        window.clear
        window.noutrefresh
        all.each(&:draw)
      end

      def create(attributes)
        tabs[attributes[:id]] = new attributes
      end

      def remove(id)
        tab = find(id)
        tab.deactivate
        tab.window.close
        tabs.delete(id)
        draw
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
        threshold = Time.now - 2
        all.select { |t| t.last_ping_at && t.last_ping_at < threshold }
      end
    end

    def height
      3
    end

    def width
      5
    end

    def top
      Tab.window.begy
    end

    def left
      Tab.window.begx + index * width
    end

    def window
      @window ||= create_window(height: height, width: width, top: top, left: left)
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

    def index
      Tab.all.index(self)
    end

    def session
      BR::SessionManager[id]
    end

    def status
      session.test_results.status
    end

    def active?
      active
    end

    def activate
      return if active?

      if tab = Tab.active
        tab.deactivate
      end

      self.active = true
      draw

      Tab.status_window.addstr(session.to_s)
      Tab.status_window.noutrefresh

      Tab.content_window.addstr(session.test_results.to_s)
      Tab.content_window.noutrefresh
    end

    def deactivate
      return unless active?

      self.active = false
      draw

      Tab.status_window.clear
      Tab.status_window.noutrefresh

      Tab.content_window.clear
      Tab.content_window.noutrefresh
    end

    def activate_next
      tabs = Tab.all

      if tabs.last == self
        tabs.first.activate
      elsif tab = tabs[index + 1]
        tab.activate
      end
    end

    def activate_previous
      tabs = Tab.all

      if tabs.first == self
        tabs.last.activate
      elsif tab = tabs[index - 1]
        tab.activate
      end
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
    BR::Assets.watch_logical_paths
  end

  def stop
    Curses.close_screen
  end

  def run
    start_screen
    init_windows
    handle_keys
    handle_stale_tabs

    BR.subscribe("/results") do |details|
      session = BR::SessionManager[details["session_id"]]

      if tab = Tab.find(session.id)
        if details["line"] && tab.active?
          Tab.content_window.addstr(details["line"] + "\n")
          Tab.content_window.noutrefresh
        end
        tab.draw
      else
        tab = Tab.create(id: session.id)
        tab.activate if Tab.size == 1
      end

      Curses.doupdate
    end
  end

  private
    def start_screen
      Curses.init_screen
      Curses.start_color
      Curses.noecho
      Curses.curs_set(0)
      Curses.stdscr.keypad(true)
    end

    def init_windows
      header_window = create_window(height: 3)
      header_window.attron(Curses::A_BOLD)
      header_window.addstr "BLADE RUNNER [press 'q' to quit]\n"
      header_window.attroff(Curses::A_BOLD)
      header_window.addstr "Open #{BR.blade_url} to start"
      header_window.noutrefresh

      Tab.install(top: header_window.maxy)

      Curses.doupdate
    end

    def handle_keys
      EM.defer do
        while ch = Curses.getch
          case ch
          when Curses::KEY_LEFT
            Tab.active.activate_previous
            Curses.doupdate
          when Curses::KEY_RIGHT
            Tab.active.activate_next
            Curses.doupdate
          when "q"
            BR.stop
          end
        end
      end
    end

    def handle_stale_tabs
      BR.subscribe("/browsers") do |details|
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

    def remove_tab(tab)
      Tab.remove(tab.id)
      Curses.doupdate
    end
end
