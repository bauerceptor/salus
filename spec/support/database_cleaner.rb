RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
    seed_roles
    seed_measurement_types
  end

  config.before(:each) do
    if Capybara.current_driver == :selenium_chrome_headless
      begin
        Capybara.current_session.driver.browser.manage.delete_all_cookies
      rescue Selenium::WebDriver::Error::NoSuchDriverError, Selenium::WebDriver::Error::SessionNotCreatedError
        nil
      end
    end
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
    if Capybara.current_driver == :selenium_chrome_headless
      begin
        Capybara.current_session.driver.browser.manage.delete_all_cookies
      rescue Selenium::WebDriver::Error::NoSuchDriverError, Selenium::WebDriver::Error::SessionNotCreatedError
        nil
      end
    end
  end

  def seed_roles
    Role.find_or_create_by(name: "patient")
    Role.find_or_create_by(name: "specialist")
    Role.find_or_create_by(name: "caregiver")
    Role.find_or_create_by(name: "admin")
  end

  def seed_measurement_types
    return if MeasurementType.exists?

    weight_unit = Unit.find_or_create_by!(symbol: "kg") do |u|
      u.name = "Kilogram"
    end
    sugar_unit = Unit.find_or_create_by!(symbol: "mmol/L") do |u|
      u.name = "Millimole per liter"
    end
    heart_unit = Unit.find_or_create_by!(symbol: "bpm") do |u|
      u.name = "Beats per minute"
    end
    bp_unit = Unit.find_or_create_by!(symbol: "mmHg") do |u|
      u.name = "Millimeter of mercury"
    end
    spo2_unit = Unit.find_or_create_by!(symbol: "%") do |u|
      u.name = "Percentage"
    end

    MeasurementType.find_or_create_by!(name: "weight", unit: weight_unit)
    MeasurementType.find_or_create_by!(name: "sugar", unit: sugar_unit) do |mt|
      mt.lower_limit = 70
      mt.upper_limit = 99
    end
    MeasurementType.find_or_create_by!(name: "heart_beat", unit: heart_unit) do |mt|
      mt.lower_limit = 60
      mt.upper_limit = 100
    end
    MeasurementType.find_or_create_by!(name: "blood_pressure", unit: bp_unit) do |mt|
      mt.lower_limit = "100/60"
      mt.upper_limit = "139/89"
    end
    MeasurementType.find_or_create_by!(name: "spo2", unit: spo2_unit) do |mt|
      mt.lower_limit = 90
      mt.upper_limit = 100
    end
  end
end
