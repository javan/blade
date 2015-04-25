class BladeRunner::Firefox < BladeRunner::Browser
  def name
    "Firefox"
  end

  def start
    @driver = Selenium::WebDriver.for :firefox
    @driver.navigate.to test_url
  end

  def stop
    @driver.quit
  end
end
