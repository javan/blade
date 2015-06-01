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
    @passes = 0
    @failures = 0
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
      klass = details["result"] ? Pass : Failure
      result = klass.new(details["name"], details["message"])
      @lines << publication[:line] = result.to_s
    when "end"
      @status = "finished" unless failures > 0
      @completed = true
    end

    publication.merge!(status: status, session_id: session_id)
    publish("/results", publication)
  end

  def record_result(result)
    case result
    when Failure
      @failures += 1
      @status = "failed"
    when Pass
      @passes += 1
    end

    result
  end

  def total
    if @total
      @total
    elsif @completed
      passes + failures
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

  class Combiner
    attr_reader :all_test_results

    def initialize(all_test_results)
      @all_test_results = all_test_results
    end

    def total
      totals = all_test_results.map(&:total)
      if totals.all?
        totals.inject(0) { |sum, total| sum + total }
      end
    end

    def sorted_results
      passes, failures = [], []

      all_test_results.each do |test_results|
        passes.push(*test_results.passes)
        failures.push(*test_results.failures)
      end

      passes + failures
    end

    def to_s
      lines = []

      sorted_results.each_with_index do |result, index|
        lines << result.to_s(index + 1)
      end

      lines = lines.unshift("1..#{total}") if total
      lines.join("\n")
    end
  end
end
