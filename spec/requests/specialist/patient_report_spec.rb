require "rails_helper"

RSpec.describe "Specialist::PatientReport", type: :request do
  let(:specialist_user) { create(:user, :specialist) }
  let(:patient_account) do
    create(:account, first_name: "Maria", last_name: "Garcia", city: "Warsaw", country: "Poland")
  end

  before do
    create(:specialist_patient, specialist: specialist_user, account: patient_account, status: "active")
    sign_in specialist_user
  end

  describe "GET /specialist/patients/:id/report" do
    it "returns a PDF file for a linked patient" do
      get report_specialist_patient_path(id: patient_account)
      expect(response.media_type).to eq("application/pdf")
    end

    it "sets Content-Disposition attachment header with filename" do
      get report_specialist_patient_path(id: patient_account)
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.headers["Content-Disposition"]).to match(/filename="patient_report_[a-f0-9-]+_\d{8}_\d{6}\.pdf"/)
    end

    it "returns PDF with valid header" do
      get report_specialist_patient_path(id: patient_account)
      expect(response.body).to start_with("%PDF")
    end

    it "returns 404 for unlinked patient" do
      unlinked = create(:account)
      get report_specialist_patient_path(id: unlinked)
      expect(response).to have_http_status(:not_found)
    end

    context "with patient data" do
      before do
        create(:predefined_disease, name: "Type 2 Diabetes", icd10_code: "E11")
        create(:disease, account: patient_account,
                         predefined_disease: create(:predefined_disease, name: "Hypertension", icd10_code: "I10"))
        create(:medication, account: patient_account, name: "Metformin", dosage: "500mg", frequency: "twice_daily")
        create(:specialist_note, account: patient_account, specialist: specialist_user, note_type: "observation",
                                 content: "Patient doing well")
      end

      it "generates PDF with substantial content" do
        get report_specialist_patient_path(id: patient_account)
        expect(response.body.length).to be > 1000
      end
    end
  end
end
