require "curses"

module Blade::Runner
  extend self
  include Blade::Component

  autoload :Tab, "blade/interface/runner/tab"

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

  def start
    run
    Blade::Assets.watch_logical_paths
  end

  def stop
    Curses.close_screen
  end

  def run
    start_screen
    init_windows
    handle_keys
    handle_stale_tabs

    Blade.subscribe("/results") do |details|
      session = Blade::Session.find(details[:session_id])

      unless tab = Tab.find(session.id)
        tab = Tab.create(id: session.id)
        tab.activate if Tab.size == 1
      end

      tab.draw
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
      header_window.addstr "Open #{Blade.url} to start"
      header_window.noutrefresh

      Tab.install(top: header_window.maxy)

      Curses.doupdate
    end

    def handle_keys
      EM.defer do
        while ch = Curses.getch
          case ch
          when Curses::KEY_LEFT
            Tab.active.try(:activate_previous)
            Curses.doupdate
          when Curses::KEY_RIGHT
            Tab.active.try(:activate_next)
            Curses.doupdate
          when "q"
            Blade.stop
          end
        end
      end
    end

    def handle_stale_tabs
      Blade.subscribe("/browsers") do |details|
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
