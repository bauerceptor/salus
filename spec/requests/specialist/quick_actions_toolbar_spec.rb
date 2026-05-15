require "rails_helper"

RSpec.describe "Specialist::QuickActionsToolbar", type: :request do
  let(:specialist_user) { create(:user, :specialist) }
  let(:patient_account) { create(:account) }

  before do
    create(:specialist_patient, specialist: specialist_user, account: patient_account, status: "active")
    sign_in specialist_user
  end

  describe "GET /specialist/patients/search" do
    it "returns search results HTML with patient names" do
      get search_specialist_patients_path(q: patient_account.first_name)
      expect(response.body).to include("quick-actions-toolbar__search-results")
      expect(response.body).to include(patient_account.full_name)
    end

    it "returns empty state when no results" do
      get search_specialist_patients_path(q: "zzz_no_patient_matches_this_123")
      expect(response.body).to include("quick-actions-toolbar__search-empty")
    end

    it "returns patient link that navigates to patient detail" do
      get search_specialist_patients_path(q: patient_account.first_name)
      expect(response.body).to include("href=\"/en/specialist/patients/")
      expect(response.body).to include(patient_account.id.to_s)
    end
  end

  describe "Specialist::PatientsController#search" do
    it "limits results to 10 patients" do
      15.times { create(:account) }
      get search_specialist_patients_path(q: "")
      expect(response.body).not_to include("quick-actions-toolbar__search-empty")
    end

    it "only returns active patients for the current specialist" do
      other_account = create(:account)
      get search_specialist_patients_path(q: other_account.first_name)
      expect(response.body).not_to include(other_account.full_name)
    end
  end
end
