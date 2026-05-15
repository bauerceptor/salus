require "rails_helper"

RSpec.describe LinkPreviewService do
  describe "#call" do
    let(:service) { described_class.new(url) }

    context "with a valid URL" do
      let(:url) { "https://example.com/article" }
      let(:html_content) do
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <meta property="og:title" content="Example Article">
              <meta property="og:description" content="This is an example article description">
              <meta property="og:image" content="https://example.com/image.jpg">
            </head>
            <body></body>
          </html>
        HTML
      end

      before do
        allow(HTTParty).to receive(:get).and_return(
          instance_double(HTTParty::Response, success?: true, body: html_content)
        )
      end

      it "returns a hash with title, description, and image" do
        preview = service.call
        expect(preview).to be_a(Hash)
        expect(preview[:title]).to eq("Example Article")
        expect(preview[:description]).to eq("This is an example article description")
        expect(preview[:image]).to eq("https://example.com/image.jpg")
      end
    end

    context "with an invalid URL" do
      let(:url) { "not-a-valid-url" }

      it "returns nil gracefully" do
        preview = service.call
        expect(preview).to be_nil
      end
    end

    context "with a URL that returns no Open Graph tags" do
      let(:url) { "http://localhost:9999/nonexistent" }

      before do
        allow(HTTParty).to receive(:get).and_raise(StandardError.new("Connection refused"))
      end

      it "returns nil gracefully" do
        preview = service.call
        expect(preview).to be_nil
      end
    end

    context "with a URL that has no og:title" do
      let(:url) { "https://example.com/no-og" }
      let(:html_content) do
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <meta property="og:description" content="Description without title">
            </head>
            <body></body>
          </html>
        HTML
      end

      before do
        allow(HTTParty).to receive(:get).and_return(
          instance_double(HTTParty::Response, success?: true, body: html_content)
        )
      end

      it "returns nil when no title is found" do
        preview = service.call
        expect(preview).to be_nil
      end
    end
  end
end
