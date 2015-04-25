require "uri"

class BladeRunner::Browser
  include BladeRunner::Knife

  attr_reader :test_results

  class << self
    attr_reader :subclasses

    def inherited(subclass)
      @subclasses ||= []
      @subclasses << subclass
    end
  end

  def initialize
    @test_results = BladeRunner::TestResults.new(self)
  end

  def name
    raise NotImplementedError
  end

  def start
    raise NotImplementedError
  end

  def stop
    raise NotImplementedError
  end

  def test_url
    URI.escape("http://localhost:#{config.port}/blade/#{config.framework}.html?browser=#{name}&time=#{Time.now.utc}")
  end

  def supported?
    true
  end
end
