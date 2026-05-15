require "rails_helper"

RSpec.describe "User Registration", type: :feature do
  describe "User signs up" do
    scenario "user successfully registers" do
      visit auth_new_registration_path

      fill_in "E-Mail", with: "newuser@example.com"
      fill_in "Password", with: "password123"
      fill_in "Confirm Password", with: "password123"
      check "user_tos_agreement"
      click_button "Register"

      expect(page).to have_content("Complete Profile")
      expect(page).to have_current_path(setup_account_path)
    end

    scenario "user registers and completes profile" do
      visit auth_new_registration_path

      fill_in "E-Mail", with: "newuser@example.com"
      fill_in "Password", with: "password123"
      fill_in "Confirm Password", with: "password123"
      check "user_tos_agreement"
      click_button "Register"

      fill_in "First Name", with: "John"
      fill_in "Last Name", with: "Doe"
      fill_in "Username", with: "johndoe"
      click_button "Get Started"

      expect(page).to have_content("Welcome")
      expect(page).to have_current_path(authenticated_root_path)
    end

    scenario "user registration fails with invalid data" do
      visit auth_new_registration_path

      fill_in "E-Mail", with: ""
      fill_in "Password", with: "short"
      click_button "Register"

      expect(page).to have_content("Error")
    end
  end

  describe "User signs in" do
    let(:user) { create(:user, password: "password123") }

    scenario "user successfully signs in" do
      visit auth_new_session_path

      fill_in "E-Mail", with: user.email
      fill_in "Password", with: "password123"
      click_button "Sign In"

      expect(page).to have_content("Welcome")
    end

    scenario "user signs in with invalid credentials" do
      visit auth_new_session_path

      fill_in "E-Mail", with: user.email
      fill_in "Password", with: "wrongpassword"
      click_button "Sign In"

      expect(page).to have_content("Invalid email or password")
    end
  end

  describe "User signs out" do
    let(:user) { create(:user) }

    scenario "user successfully signs out" do
      visit auth_new_session_path
      fill_in "E-Mail", with: user.email
      fill_in "Password", with: user.password
      click_button "Sign In"

      click_button "Logout"

      expect(page).to have_content("Sign In")
      expect(page).to have_current_path(root_path)
    end
  end
end
