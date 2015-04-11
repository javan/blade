class BladeRunner::Chrome < BladeRunner::Browser
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
