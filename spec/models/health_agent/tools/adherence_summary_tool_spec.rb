require "rails_helper"

RSpec.describe HealthAgent::Tools::AdherenceSummaryTool do
  let(:account) { create(:account) }
  let(:tool) { described_class.new }

  describe "#execute" do
    it "returns adherence summary hash" do
      result = tool.execute(patient_id: account.id)

      expect(result).to be_a(Hash)
      expect(result["account_id"]).to eq(account.id)
      expect(result["overall_adherence"]).to be_a(Float)
      expect(result["total_medications"]).to be_a(Integer)
    end

    it "calculates medication adherence percentage" do
      create_list(:medication, 3, account: account, is_active: true)

      result = tool.execute(patient_id: account.id)

      expect(result["total_medications"]).to eq(3)
      expect(result["active_medications"]).to eq(3)
    end

    it "calculates adherence from medication logs" do
      active_med = create(:medication, account: account, is_active: true)

      create_list(:medication_log, 8, medication: active_med, status: :taken)
      create_list(:medication_log, 2, medication: active_med, status: :missed)

      result = tool.execute(patient_id: account.id)

      expect(result["taken_count"]).to eq(8)
      expect(result["missed_count"]).to eq(2)
    end

    it "handles patient with no medications" do
      result = tool.execute(patient_id: account.id)

      expect(result["total_medications"]).to eq(0)
      expect(result["active_medications"]).to eq(0)
      expect(result["overall_adherence"]).to eq(100.0)
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
