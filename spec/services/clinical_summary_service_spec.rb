require "rails_helper"

RSpec.describe ClinicalSummaryService do
  let(:account) { build_stubbed(:account) }
  let(:service) { described_class.new(account) }

  describe "#generate_summary_text" do
    it "returns a string summary" do
      result = service.generate_summary_text
      expect(result).to be_a(String)
    end

    it "returns non-empty text" do
      result = service.generate_summary_text
      expect(result.length).to be > 0
    end
  end

  describe "#call" do
    it "returns a hash with summary and metadata" do
      result = service.call
      expect(result).to be_a(Hash)
      expect(result.keys).to include(:summary_text, :generated_at, :confidence)
    end
  end
end
