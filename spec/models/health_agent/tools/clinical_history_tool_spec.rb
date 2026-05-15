require "rails_helper"

RSpec.describe HealthAgent::Tools::ClinicalHistoryTool do
  let(:account) { create(:account) }
  let(:specialist) { create(:specialist) }
  let(:tool) { described_class.new }

  describe "#execute" do
    it "returns clinical history summary" do
      result = tool.execute(patient_id: account.id)

      expect(result).to be_a(Hash)
      expect(result["account_id"]).to eq(account.id)
      expect(result["conditions_count"]).to be_a(Integer)
      expect(result["medications_count"]).to be_a(Integer)
      expect(result["recent_measurements_count"]).to be_a(Integer)
    end

    it "includes diseases count" do
      create_list(:disease, 2, account: account)

      result = tool.execute(patient_id: account.id)

      expect(result["conditions_count"]).to eq(2)
    end

    it "includes active medications count" do
      create_list(:medication, 3, account: account, is_active: true)

      result = tool.execute(patient_id: account.id)

      expect(result["medications_count"]).to eq(3)
    end

    it "includes recent measurements" do
      blood_sugar_type = create(:sugar_measurement_type)
      create_list(:measurement, 5, :sugar, account: account, measurement_type: blood_sugar_type)

      result = tool.execute(patient_id: account.id)

      expect(result["recent_measurements_count"]).to eq(5)
    end

    it "includes adherence rate" do
      active_med = create(:medication, account: account, is_active: true)
      create_list(:medication_log, 7, medication: active_med, account: account, status: :taken)
      create_list(:medication_log, 3, medication: active_med, account: account, status: :missed)

      result = tool.execute(patient_id: account.id)

      expect(result["adherence_rate"]).to be_a(Float)
      expect(result["adherence_rate"]).to eq(70.0)
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
