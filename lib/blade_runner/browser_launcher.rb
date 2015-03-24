require "childprocess"

class BladeRunner
  class BrowserLauncher < Base
    def start
      browsers.each do |name, args|
        args = args + [url(name)]
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
          "--no-first-run"
        ],
        "Firefox" => [
          "/Applications/Firefox.app/Contents/MacOS/firefox"
        ],
        #"Safari" => [
        #  "/Applications/Safari.app/Contents/MacOS/Safari",
        #  url
        #]
      }
    end

    def url(browser)
      "http://localhost:#{runner.config.port}/test.html?browser=#{browser}"
    end
  end
end
