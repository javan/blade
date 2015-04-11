require "childprocess"
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

  def command
    raise NotImplementedError
  end

  def start
    @process = ChildProcess.build(*command_with_arguments)
    @process.start
  end

  def stop
    @process.stop
  end

  def arguments
  end

  def command_with_arguments
    [command, arguments, test_url].flatten.compact
  end

  def test_url
    URI.escape("http://localhost:#{config.port}/blade/#{config.framework}.html?browser=#{name}&time=#{Time.now.utc}")
  end

  def supported?
    File.exists?(command)
  end
end