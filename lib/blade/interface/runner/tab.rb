class Blade::Runner::Tab < Blade::Model
  delegate :colors, :create_window, to: Blade::Runner

  class << self
    delegate :create_window, to: Blade::Runner

    attr_reader :window, :state_window, :content_window

    def install(options = {})
      top = options[:top]
      @window = create_window(top: top, height: 3)

      top = @window.begy + @window.maxy + 1
      @state_window = create_window(top: top, height: 1)

      top = @state_window.begy + @state_window.maxy + 1
      @content_window = create_window(top: top)
      @content_window.scrollok(true)
    end

    def draw
      window.clear
      window.noutrefresh
      all.each(&:draw)
    end

    def remove(id)
      tab = find(id)
      tab.deactivate
      tab.window.close
      super
      draw
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
    draw_test_results
  end

  def draw_inactive
    window.addstr "\n"
    window.attron(color)
    window.addstr("  #{dot}\n")
    window.attroff(color)
    window.addstr "═════"
  end

  def draw_test_results
    tabs.content_window.clear
    failures = []

    session.test_results.results.each do |result|
      tabs.content_window.addstr(status_dot(result))
      failures << result if result[:status] == "fail"
    end

    failures.each do |result|
      tabs.content_window.addstr("\n\n")
      tabs.content_window.attron(Curses::A_BOLD)
      tabs.content_window.attron(colors.red)
      tabs.content_window.addstr("#{status_dot(result)} #{result[:name]}\n")
      tabs.content_window.attroff(colors.red)
      tabs.content_window.attroff(Curses::A_BOLD)
      tabs.content_window.addstr(result[:message])
    end

    tabs.content_window.noutrefresh
  end

  def dot
    state == "pending" ? "○" : "●"
  end

  def status_dot(result)
    Blade::TestResults::STATUS_DOTS[result[:status]]
  end

  def index
    tabs.all.index(self)
  end

  def session
    Blade::Session.find(id)
  end

  def state
    session.test_results.state
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

    tabs.state_window.addstr(session.to_s)
    tabs.state_window.noutrefresh
  end

  def deactivate
    return unless active?

    self.active = false
    draw

    tabs.state_window.clear
    tabs.state_window.noutrefresh

    tabs.content_window.clear
    tabs.content_window.noutrefresh
  end

  def activate_next
    all = tabs.all

    if all.last == self
      all.first.activate
    elsif tab = all[index + 1]
      tab.activate
    end
  end

  def activate_previous
    all = tabs.all

    if all.first == self
      all.last.activate
    elsif tab = all[index - 1]
      tab.activate
    end
  end

  def color
    case state
    when "running"  then colors.yellow
    when "finished" then colors.green
    when /fail/     then colors.red
    else                 colors.white
    end
  end
end
