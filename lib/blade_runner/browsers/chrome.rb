class BladeRunner::Chrome < BladeRunner::Browser
  def name
    "Chrome"
  end

  def start
    @driver = Selenium::WebDriver.for :chrome
    @driver.navigate.to test_url
  end

  def stop
    @driver.quit
  end
end
