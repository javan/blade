class Blade::TestResults
  attr_reader :session_id, :status, :lines, :passes, :failures, :total

  def initialize(session_id)
    @session_id = session_id
    reset

    Blade.subscribe("/tests") do |details|
      if details["session_id"] == session_id
        process_test_result(details)
      end
    end
  end

  def reset
    @lines = []
    @passes = []
    @failures = []
    @status = "pending"
    @total = 0
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
      args = details.values_at("name", "message")

      if details["status"] == "pass"
        line = Pass.new(*args).to_s
        @passes << line
      else
        line = Failure.new(*args).to_s
        @failures << line
        @status = "failing"
      end
      @lines << line

      publication.merge!(line: line, status: status)
    when "end"
      @status = failures.any? ? "failed" : "finished"
      publication[:completed] = true
    end

    publication.merge!(status: status, session_id: session_id)
    Blade.publish("/results", publication)
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
