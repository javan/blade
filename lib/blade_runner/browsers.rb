require "childprocess"
require "uri"

class BladeRunner
  class Browser < Base
    def name
      raise NotImplementedError
    end

    def command
      raise NotImplementedError
    end

    def start
      process = ChildProcess.build(*command_with_arguments)
      process.start
    end

    def arguments
    end

    def command_with_arguments
      [command, arguments, test_url].flatten.compact
    end

    def test_url
      URI.escape("http://localhost:#{runner.config.port}/test.html?browser=#{name}")
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
      ["--user-data-dir=#{runner.tmp_path}", "--no-default-browser-check", "--no-first-run"]
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
      path = runner.tmp_path.join("#{name}.html").to_s
      File.write(path, contents)
      path
    end
  end
end


