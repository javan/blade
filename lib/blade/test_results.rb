class Blade::TestResults
  STATUS_DOTS = { pass: ".", fail: "✗" }.with_indifferent_access

  attr_reader :session_id, :state, :results, :total, :failures

  def initialize(session_id)
    @session_id = session_id
    reset

    Blade.subscribe("/tests") do |details|
      if details[:session_id] == session_id
        event = details.delete(:event)
        try("process_#{event}", details)
      end
    end
  end

  def reset
    @results = []
    @state = "pending"
    @total = 0
    @failures = 0
  end

  def process_begin(details)
    reset
    @state = "running"
    @total = details[:total]
    publish(total: @total)
  end

  def process_result(details)
    result = details.slice(:status, :name, :message)
    @results << result

    if result[:status] == "fail"
      @state = "failing"
      @failures += 1
    end

    publish(result)
  end

  def process_end(details)
    @state = failures.zero? ? "finished" : "failed"
    publish(completed: true)
  end

  def publish(message = {})
    Blade.publish("/results", message.merge(state: state, session_id: session_id))
  end
end
