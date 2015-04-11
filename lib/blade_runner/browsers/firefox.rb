class BladeRunner::Firefox < BladeRunner::Browser
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
