require "rails_helper"

RSpec.describe ClinicalDocument do
  let(:account) { build_stubbed(:account) }
  let(:user) { build_stubbed(:user) }
  let(:document) { described_class.new(account: account, uploaded_by: user) }

  describe "attributes" do
    it "has required attributes" do
      document.document_type = "lab_result"
      document.file_data = { "filename" => "test.pdf", "content_type" => "application/pdf" }
      expect(document.valid?).to be true
    end
  end

  describe "#processed_content" do
    it "returns nil when file_data is blank" do
      document.file_data = nil
      expect(document.processed_content).to be_nil
    end

    it "returns nil when content is missing" do
      document.file_data = { "filename" => "test.pdf" }
      expect(document.processed_content).to be_nil
    end

    it "returns content when present" do
      document.file_data = { "content" => "test content" }
      expect(document.processed_content).to eq("test content")
    end
  end
end
