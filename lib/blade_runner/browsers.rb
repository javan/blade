require "blade_runner/test_results"
require "childprocess"
require "uri"

module BladeRunner
  class Browser
    include Knife

    attr_reader :test_results

    class << self
      attr_reader :subclasses

      def inherited(subclass)
        @subclasses ||= []
        @subclasses << subclass
      end
    end

    def initialize
      @test_results = TestResults.new(self)
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

  class Chrome < Browser
    def name
      "Chrome"
    end

    def command
      "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    end

    def arguments
      ["--user-data-dir=#{tmp_path}", "--no-default-browser-check", "--no-first-run"]
    end
  end

  class Firefox < Browser
    def name
      "Firefox"
    end

    def command
      "/Applications/Firefox.app/Contents/MacOS/firefox"
    end

    def arguments
      ["-new-instance", "-purgecaches", "-private"]
    end
  end

  class Safari < Browser
    def name
      "Safari"
    end

    def command
      "/Applications/Safari.app/Contents/MacOS/Safari"
    end

    def test_url
      contents = %Q(<script>window.location = "#{super}";</script>)
      path = tmp_path.join("#{name}.html").to_s
      File.write(path, contents)
      path
    end
  end
end


