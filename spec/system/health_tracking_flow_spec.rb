require "rails_helper"

RSpec.describe "Health Tracking Flow", type: :feature do
  let(:user) { create(:user) }

  before do
    visit auth_new_session_path
    fill_in "E-Mail", with: user.email
    fill_in "Password", with: user.password
    click_button "Sign In"
  end

  describe "User adds a disease" do
    let!(:predefined_disease) { create(:predefined_disease) }

    scenario "user successfully adds a disease" do
      visit diseases_path
      click_link "Add New Disease", match: :first

      select predefined_disease.name, from: "disease[predefined_disease_id]"
      check "disease_diagnosed_by_hp"
      click_button "Save"

      expect(page).to have_content(predefined_disease.name)
    end
  end

  describe "User adds a medication" do
    let!(:disease) { create(:disease, account: user.account) }

    scenario "user successfully adds a medication" do
      visit medications_path
      click_link "Add Medication", match: :first

      fill_in "medication[name]", with: "Aspirin"
      fill_in "medication[dosage]", with: "500mg"
      select "Once daily", from: "medication[frequency]"
      click_button "Save"

      expect(page).to have_content("Aspirin")
    end
  end

  describe "User adds a note" do
    scenario "user successfully adds a note" do
      visit notes_path
      click_link "Add Note", match: :first

      fill_in "note[title]", with: "Doctor's Visit"
      fill_in "note[content]", with: "Discussed treatment options"
      click_button "Save"

      expect(page).to have_content("Doctor's Visit")
    end

    scenario "user pins a note" do
      visit notes_path
      click_link "Add Note", match: :first

      fill_in "note[title]", with: "Important Note"
      fill_in "note[content]", with: "Remember to take medication"
      check "note_is_pinned"
      click_button "Save"

      expect(page).to have_content("Important Note")
    end
  end
end
