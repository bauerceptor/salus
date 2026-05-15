require "rails_helper"

RSpec.describe HealthEmbedding, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
  end

  describe "enums" do
    it "defines embedding types" do
      expect(described_class::EMBEDDING_TYPES.values).to include(
        "patient_message", "specialist_response", "anonymized_pattern", "adherence_event"
      )
    end
  end

  describe "scopes" do
    let(:account) { create(:account) }

    describe "#validated" do
      it "returns only validated embeddings" do
        validated = create(:health_embedding, account: account, validated: true)
        create(:health_embedding, account: account, validated: false)

        expect(described_class.validated).to include(validated)
        expect(described_class.validated.count).to eq(1)
      end
    end

    describe "#by_type" do
      it "returns embeddings of specific type" do
        patient_emb = create(:health_embedding, account: account, embedding_type: "patient_message")
        create(:health_embedding, account: account, embedding_type: "anonymized_pattern")

        expect(described_class.by_type("patient_message")).to include(patient_emb)
        expect(described_class.by_type("patient_message").count).to eq(1)
      end
    end
  end

  describe ".embed_and_store" do
    let(:account) { create(:account) }
    let(:mock_embedding_result) do
      instance_double(RubyLLM::Embedding, vectors: [0.1, 0.2, 0.3] * 512)
    end

    before do
      allow(RubyLLM).to receive(:embed).and_return(mock_embedding_result)
    end

    it "creates embedding with correct attributes" do
      embedding = described_class.embed_and_store(
        content: "Test content",
        embedding_type: "patient_message",
        account: account,
        metadata: { source: "test" }
      )

      expect(embedding.account).to eq(account)
      expect(embedding.content).to eq("Test content")
      expect(embedding.embedding_type).to eq("patient_message")
      expect(embedding.metadata).to eq({ "source" => "test" })
    end

    it "stores the vector from RubyLLM.embed" do
      embedding = described_class.embed_and_store(
        content: "Test content",
        embedding_type: "patient_message",
        account: account
      )

      expect(embedding.embedding).to be_a(String)
    end

    it "creates embedding with default values when metadata empty" do
      embedding = described_class.embed_and_store(
        content: "Test content",
        embedding_type: "patient_message",
        account: account
      )

      expect(embedding.confidence_score).to eq(0)
      expect(embedding.validated).to be(false)
    end
  end

  describe ".similarity_search" do
    let(:account) { create(:account) }
    let(:mock_query_embedding) do
      instance_double(RubyLLM::Embedding, vectors: [0.1] * 1536)
    end

    before do
      allow(RubyLLM).to receive(:embed).with("test query").and_return(mock_query_embedding)
    end

    it "searches within account scope only" do
      other_account = create(:account)
      create(:health_embedding, account: account, embedding_type: "patient_message", validated: true,
                                embedding_array: [0.1] * 1536)
      create(:health_embedding, account: other_account, embedding_type: "patient_message", validated: true,
                                embedding_array: [0.2] * 1536)

      results = described_class.similarity_search(query: "test query", account: account)

      expect(results.to_a.size).to eq(1)
      expect(results.first.account).to eq(account)
    end

    it "filters by embedding_type when provided" do
      create(:health_embedding, account: account, embedding_type: "patient_message", validated: true,
                                embedding_array: [0.1] * 1536)
      create(:health_embedding, account: account, embedding_type: "anonymized_pattern", validated: true,
                                embedding_array: [0.2] * 1536)

      results = described_class.similarity_search(
        query: "test query",
        account: account,
        embedding_type: "patient_message"
      )

      expect(results.to_a.size).to eq(1)
      expect(results.first.embedding_type).to eq("patient_message")
    end

    it "limits results to specified count" do
      10.times do
        create(:health_embedding, account: account, embedding_type: "patient_message", validated: true,
                                  embedding_array: [0.1] * 1536)
      end

      results = described_class.similarity_search(
        query: "test query",
        account: account,
        limit: 3
      )

      expect(results.to_a.size).to eq(3)
    end

    it "returns empty relation when no matches" do
      results = described_class.similarity_search(query: "test query", account: account)
      expect(results.to_a).to be_empty
    end
  end
end
