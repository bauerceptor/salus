require "rails_helper"

RSpec.describe "Treatment Request Flow", type: :feature do
  let(:patient_user) { create(:user) }
  let(:specialist_user) { create(:user, :specialist) }
  let(:specialist) { create(:specialist, user: specialist_user) }
  let(:patient_account) { patient_user.account }

  before do
    Capybara.reset_sessions!
    specialist
    create(:specialist_patient, specialist: specialist_user, account: patient_account, status: "active")
  end

  describe "Patient creates treatment request" do
    scenario "patient successfully requests a treatment" do
      visit auth_new_session_path
      fill_in "E-Mail", with: patient_user.email
      fill_in "Password", with: patient_user.password
      click_button "Sign In"

      first(:link, "Treatments").click
      click_link "Request Treatment"

      fill_in "treatment_request[title]", with: "Physical Therapy"
      fill_in "treatment_request[description]", with: "Weekly rehabilitation sessions"
      select_date 1.month.from_now, field: "treatment_request_start_date"
      click_button "Save"

      expect(page).to have_content("Treatment Requests")
      expect(page).to have_content("Physical Therapy")
      expect(page).to have_content("Pending")
    end

    scenario "patient cancels pending request" do
      request = create(:treatment_request, account: patient_account, status: "pending")

      visit auth_new_session_path
      fill_in "E-Mail", with: patient_user.email
      fill_in "Password", with: patient_user.password
      click_button "Sign In"

      visit patient_treatment_requests_path

      card = find(".treatment-request-card", text: request.title)
      within(card) do
        click_button "Cancel Request"
      end

      expect(page).not_to have_content(request.title)
    end
  end

  describe "Specialist approves treatment request" do
    scenario "specialist approves and treatment is created" do
      request = create(:treatment_request, account: patient_account, status: "pending")

      visit specialist_new_session_path
      fill_in "Email", with: specialist_user.email
      fill_in "Password", with: specialist_user.password
      click_button "Sign In"

      expect(page).to have_content("Treatment Requests")

      within(".request-card", text: request.title) do
        expect(page).to have_content(request.title)
      end

      find("form[action*='status=approved'] button").click

      expect(page).not_to have_selector(".request-item", text: request.title)

      sign_out_for_specialist
      page.reset!
      visit auth_new_session_path
      fill_in "E-Mail", with: patient_user.email
      fill_in "Password", with: patient_user.password
      click_button "Sign In"

      visit patient_treatment_requests_path
      expect(page).to have_content(request.title)
    end

    scenario "specialist rejects treatment request" do
      request = create(:treatment_request, account: patient_account, status: "pending")

      visit specialist_new_session_path
      fill_in "Email", with: specialist_user.email
      fill_in "Password", with: specialist_user.password
      click_button "Sign In"

      find("form[action*='status=rejected'] button").click

      expect(page).not_to have_selector(".request-item", text: request.title)

      sign_out_for_specialist
      page.reset!
      visit auth_new_session_path
      fill_in "E-Mail", with: patient_user.email
      fill_in "Password", with: patient_user.password
      click_button "Sign In"

      visit patient_treatment_requests_path

      within(".treatment-request-card", text: request.title) do
        expect(page).to have_content("Rejected")
      end
    end
  end

  def select_date(date, field:)
    fill_in field, with: date.strftime("%Y-%m-%d")
  end

  def sign_out_for_specialist
    click_button "Logout"
    page.driver.reset!
  end
end
