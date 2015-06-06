class BladeRunner::TestResults
  include BladeRunner::Knife

  attr_reader :session_id, :status, :lines, :passes, :failures

  def initialize(session_id)
    @session_id = session_id
    reset

    subscribe("/tests") do |details|
      if details["session_id"] == session_id
        process_test_result(details)
      end
    end
  end

  def reset
    @lines = []
    @passes = []
    @failures = []
    @completed = false
    @status = "pending"
    @total = nil
  end

  def process_test_result(details)
    publication = {}

    case details["event"]
    when "begin"
      reset
      @status = "running"
      @total = details["total"]
      @lines << publication[:line] = "1..#{@total}"
    when "result"
      pass = details["result"]
      args = details.values_at("name", "message")

      if pass
        line = Pass.new(*args).to_s
        @passes << line
      else
        line = Failure.new(*args).to_s
        @failures << line
        @status = "failing"
      end
      @lines << line

      publication.merge!(line: line, pass: pass)
    when "end"
      @status = failures.any? ? "failed" : "finished"
      @completed = true
    end

    publication.merge!(status: status, session_id: session_id, completed: @completed)
    publish("/results", publication)
  end

  def total
    if @total
      @total
    elsif @completed
      passes.size + failures.size
    end
  end

  def to_s
    lines.join("\n") + "\n"
  end

  class Pass
    def initialize(name, message)
      @name = name
      @message = message
    end

    def to_s(number = nil)
      ["ok", number, @name, message].compact.join(" ")
    end

    def message
      unless @message.nil?
        "\n" + @message.gsub(/^/, "# ").chomp
      end
    end
  end

  class Failure < Pass
    def to_s(*args)
      "not #{super}"
    end
  end
end
