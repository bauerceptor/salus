require "rails_helper"

RSpec.describe "Social Flow", type: :feature do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:other_account) { other_user.account }

  before do
    visit auth_new_session_path
    fill_in "E-Mail", with: user.email
    fill_in "Password", with: user.password
    click_button "Sign In"
  end

  describe "User sends friend request" do
    scenario "user views accounts page" do
      visit accounts_path
      expect(page).to have_content("All People")
    end

    scenario "user views friend requests" do
      create(:friend_request, account: other_account, friend: user.account)

      visit friend_requests_path

      expect(page).to have_content(other_account.full_name)
    end
  end

  describe "User manages groups" do
    scenario "user sees assigned groups for their diseases" do
      predefined_disease = create(:predefined_disease, :liver_related)
      create(:disease, account: user.account, predefined_disease: predefined_disease)

      visit groups_path

      expect(page).to have_content("My Disease Groups")
      expect(page).to have_content(predefined_disease.name.titleize)
    end

    scenario "user sees available groups for diseases they do not have" do
      predefined_disease = create(:predefined_disease, :liver_related)
      _group = create(:group, predefined_disease: predefined_disease)

      visit groups_path

      expect(page).to have_content("Available Disease Groups")
      expect(page).to have_content(predefined_disease.name.titleize)
    end

    scenario "user sees all disease groups regardless of type" do
      liver_disease = create(:predefined_disease, :liver_related)
      non_liver_disease = create(:predefined_disease, name: "diabetes_type_2")
      create(:group, predefined_disease: liver_disease)
      create(:group, predefined_disease: non_liver_disease)

      visit groups_path

      expect(page).to have_content(liver_disease.name.titleize)
      expect(page).to have_content(non_liver_disease.name.titleize)
    end

    scenario "user can join a group" do
      predefined_disease = create(:predefined_disease, :liver_related)
      create(:group, predefined_disease: predefined_disease)

      visit groups_path
      click_button "Join", match: :first

      expect(page).to have_content("Successfully joined")
    end

    scenario "user sees their groups count correctly" do
      predefined_disease = create(:predefined_disease, :liver_related)
      create(:disease, account: user.account, predefined_disease: predefined_disease)
      group = create(:group, predefined_disease: predefined_disease)
      user.account.groups << group

      visit groups_path

      within(".dash-group", text: "My Disease Groups") do
        expect(page).to have_content(predefined_disease.name.titleize)
      end
    end
  end
end
