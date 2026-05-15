Capybara.default_driver = :selenium_chrome_headless
Capybara.default_max_wait_time = 10
Capybara.javascript_driver = :selenium_chrome_headless

Capybara.register_driver :selenium_chrome_headless do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: Selenium::WebDriver::Options.chrome(
      args: [
        "no-sandbox",
        "disable-dev-shm-usage",
        "disable-gpu",
        "headless"
      ]
    )
  )
end