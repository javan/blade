require "childprocess"

class BladeRunner
  class BrowserLauncher < Base
    def start
      browsers.each do |name, args|
        process = ChildProcess.build(*args)
        process.start
      end
    end

    def browsers
      {
        "Chrome" => [
          "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
          "--user-data-dir=#{runner.tmp_path}",
          "--no-default-browser-check",
          "--no-first-run",
          url
        ],
        "Firefox" => [
          "/Applications/Firefox.app/Contents/MacOS/firefox",
          url
        ],
        #"Safari" => [
        #  "/Applications/Safari.app/Contents/MacOS/Safari",
        #  url
        #]
      }
    end

    def url
      "http://localhost:#{runner.config.port}/test.html"
    end
  end
end
