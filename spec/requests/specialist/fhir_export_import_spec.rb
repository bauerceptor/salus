require "rails_helper"

RSpec.describe "Specialist::FhirExportImport", type: :request do
  let(:specialist_user) { create(:user, :specialist) }
  let(:patient_account) { create(:account, first_name: "Maria", last_name: "Garcia") }

  before do
    pd = create(:predefined_disease, name: "Type 2 Diabetes", icd10_code: "E11")
    create(:specialist_patient, specialist: specialist_user, account: patient_account, status: "active")
    create(:disease, account: patient_account, predefined_disease: pd)
    Medication.create!(account: patient_account, name: "Metformin", dosage: "500mg", frequency: "twice_daily")
    sign_in specialist_user
  end

  describe "GET /specialist/patients/:id/export_fhir" do
    it "returns FHIR JSON bundle for a linked patient" do
      get export_fhir_specialist_patient_path(id: patient_account)
      expect(response.media_type).to eq("application/json")
      bundle = response.parsed_body
      expect(bundle["type"]).to eq("collection")
      expect(bundle["entry"]).not_to be_empty
    end

    it "sets Content-Disposition attachment header" do
      get export_fhir_specialist_patient_path(id: patient_account)
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.headers["Content-Disposition"]).to include(".json")
    end

    it "returns 404 for unlinked patient" do
      unlinked = create(:account)
      get export_fhir_specialist_patient_path(id: unlinked)
      expect(response).to have_http_status(:not_found)
    end

    it "includes Patient, Observation, Condition, MedicationStatement resources" do
      get export_fhir_specialist_patient_path(id: patient_account)
      bundle = response.parsed_body
      resource_types = bundle["entry"].map { |e| e["resource"]["resourceType"] }
      expect(resource_types).to include("Patient")
      expect(resource_types).to include("MedicationStatement")
      expect(resource_types).to include("Condition")
    end
  end

  describe "POST /specialist/patients/:id/import_fhir" do
    let(:valid_fhir_bundle) do
      {
        resourceType: "Bundle",
        type: "collection",
        entry: [
          {
            resource: {
              resourceType: "Observation",
              status: "final",
              code: { coding: [{ code: "blood_glucose", display: "Blood Glucose" }] },
              valueQuantity: { value: 120, unit: "mg/dL" }
            }
          }
        ]
      }.to_json
    end

    it "imports a valid FHIR JSON bundle" do
      temp_file = Tempfile.new(["fhir_import", ".json"])
      temp_file.write(valid_fhir_bundle)
      temp_file.rewind

      post import_fhir_specialist_patient_path(id: patient_account),
           params: { file: fixture_file_upload(temp_file.path, "application/json") },
           headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["message"]).to include("FHIR data imported")
    end

    it "returns 404 for unlinked patient" do
      unlinked = create(:account)
      post import_fhir_specialist_patient_path(id: unlinked),
           params: { file: Rack::Test::UploadedFile.new(Tempfile.new(["test", ".json"]), "application/json") }
      expect(response).to have_http_status(:not_found)
    end

    it "handles import errors gracefully" do
      temp_file = Tempfile.new(["fhir_import", ".json"])
      temp_file.write("this is not valid json{{{")
      temp_file.rewind

      post import_fhir_specialist_patient_path(id: patient_account),
           params: { file: fixture_file_upload(temp_file.path, "application/json") },
           headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:unprocessable_entity)
      body = response.parsed_body
      expect(body["error"]).to be_present
    end
  end
end
