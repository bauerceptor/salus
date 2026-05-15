require "rails_helper"

RSpec.describe HealthAgent::Tools::PatientLookupTool do
  let(:account) { create(:account, first_name: "John", last_name: "Doe", city: "New York", country: "USA") }
  let(:tool) { described_class.new }

  describe "#execute" do
    it "returns patient profile data" do
      result = tool.execute(patient_id: account.id)

      expect(result).to be_a(Hash)
      expect(result["name"]).to eq("John Doe")
      expect(result["location"]).to eq("New York, USA")
      expect(result["account_id"]).to eq(account.id)
    end

    it "includes medication count" do
      create_list(:medication, 3, account: account, is_active: true)

      result = tool.execute(patient_id: account.id)

      expect(result["medications"]).to be_a(Integer)
      expect(result["medications"]).to eq(3)
    end

    it "includes recent measurements" do
      blood_sugar_type = create(:sugar_measurement_type)
      create(:measurement, :sugar, account: account, measurement_type: blood_sugar_type)

      result = tool.execute(patient_id: account.id)

      expect(result["recent_measurements"]).to be_a(Array)
      expect(result["recent_measurements"].length).to eq(1)
    end

    it "handles missing patient gracefully" do
      fake_uuid = "00000000-0000-0000-0000-000000000000"
      result = tool.execute(patient_id: fake_uuid)

      expect(result).to be_a(Hash)
      expect(result["error"]).to be_a(String)
      expect(result["error"]).to include("not found")
    end
  end

  describe ".description" do
    it "returns tool description" do
      expect(described_class.description).to be_a(String)
      expect(described_class.description.length).to be > 10
    end
  end

  describe ".parameters" do
    it "defines patient_id parameter" do
      params = described_class.parameters
      expect(params).to be_a(Hash)
      expect(params[:patient_id]).to be_a(RubyLLM::Parameter)
    end
  end
end
