class BladeRunner::Console::Tab < OpenStruct
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

  def tabs
    self.class
  end

  def height
    3
  end

  def width
    5
  end

  def top
    tabs.window.begy
  end

  def left
    tabs.window.begx + index * width
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
    tabs.all.index(self)
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

    if tab = tabs.active
      tab.deactivate
    end

    self.active = true
    draw

    tabs.status_window.addstr(session.to_s)
    tabs.status_window.noutrefresh

    tabs.content_window.addstr(session.test_results.to_s)
    tabs.content_window.noutrefresh
  end

  def deactivate
    return unless active?

    self.active = false
    draw

    tabs.status_window.clear
    tabs.status_window.noutrefresh

    tabs.content_window.clear
    tabs.content_window.noutrefresh
  end

  def activate_next
    tabs = tabs.all

    if tabs.last == self
      tabs.first.activate
    elsif tab = tabs[index + 1]
      tab.activate
    end
  end

  def activate_previous
    tabs = tabs.all

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
