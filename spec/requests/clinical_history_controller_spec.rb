require "rails_helper"

RSpec.describe Specialist::PatientsController, type: :request do
  describe "GET #clinical_history" do
    let(:specialist_user) { create(:user, :specialist) }
    let(:patient) { create(:account) }

    before do
      create(:specialist_patient, specialist: specialist_user, account: patient, status: "active")
      sign_in specialist_user
    end

    it "returns a PDF" do
      get clinical_history_specialist_patient_path(id: patient.id)
      expect(response.media_type).to eq("application/pdf")
      expect(response.body.length).to be > 0
    end
  end
end
