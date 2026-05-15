require "rails_helper"

RSpec.describe ClinicalHistoryPdfService do
  let(:account) { build_stubbed(:account) }
  let(:specialist) { build_stubbed(:specialist) }
  let(:service) { described_class.new(account, specialist) }

  describe "#call" do
    it "returns a PDF binary" do
      result = service.call
      expect(result).to be_a(String)
      expect(result.length).to be > 0
    end

    it "starts with PDF header" do
      result = service.call
      expect(result.start_with?("%PDF")).to be true
    end
  end
end
