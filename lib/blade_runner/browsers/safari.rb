class BladeRunner::Safari < BladeRunner::Browser
  def name
    "Safari"
  end

  def start
    @driver = Selenium::WebDriver.for :safari
    @driver.navigate.to test_url
  end

  def stop
    @driver.quit
  end
end
