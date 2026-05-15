require "rails_helper"

RSpec.describe HealthRagService, type: :service do
  let(:account) { create(:account) }
  let(:specialist) { create(:user, :specialist) }
  let(:service) { described_class.new(account: account, specialist: specialist) }

  def pgvector_available?
    ActiveRecord::Base.connection.execute("SELECT 1 FROM pg_extension WHERE extname = 'vector'").any?
  rescue PG::UndefinedObject
    false
  end

  describe "#initialize" do
    it "accepts account and optional specialist" do
      expect { described_class.new(account: account) }.not_to raise_error
      expect { described_class.new(account: account, specialist: specialist) }.not_to raise_error
    end
  end

  describe "#retrieve_patient_context" do
    let(:mock_query_embedding) do
      instance_double(RubyLLM::Embedding, vectors: [0.1] * 1536)
    end

    before do
      allow(RubyLLM).to receive(:embed).and_return(mock_query_embedding)
    end

    it "returns nil when patient_rag_enabled? is false" do
      allow(service).to receive(:patient_rag_enabled?).and_return(false)

      result = service.retrieve_patient_context("test query")

      expect(result).to be_nil
    end

    it "returns concatenated content from validated embeddings" do
      skip "Requires pgvector extension" unless pgvector_available?

      allow(service).to receive(:patient_rag_enabled?).and_return(true)
      allow(service).to receive(:patient_rag_enabled?).and_return(true)

      create(:health_embedding, account: account, content: "First message", embedding_type: "patient_message",
                                validated: true, embedding_array: [0.1] * 1536)
      create(:health_embedding, account: account, content: "Second message", embedding_type: "patient_message",
                                validated: true, embedding_array: [0.1] * 1536)

      result = service.retrieve_patient_context("test query")

      expect(result).to include("First message")
      expect(result).to include("Second message")
    end

    it "limits results to 5 embeddings" do
      skip "Requires pgvector extension" unless pgvector_available?
      allow(service).to receive(:patient_rag_enabled?).and_return(true)

      7.times do
        create(:health_embedding, account: account, embedding_type: "patient_message", validated: true,
                                  embedding_array: [0.1] * 1536)
      end

      result = service.retrieve_patient_context("test query")

      embed_count = result.scan("---").count + 1
      expect(embed_count).to eq(5)
    end

    it "only includes validated embeddings" do
      skip "Requires pgvector extension" unless pgvector_available?
      allow(service).to receive(:patient_rag_enabled?).and_return(true)

      create(:health_embedding, account: account, content: "Validated content", embedding_type: "patient_message",
                                validated: true, embedding_array: [0.1] * 1536)
      create(:health_embedding, account: account, content: "Not validated", embedding_type: "patient_message",
                                validated: false, embedding_array: [0.1] * 1536)

      result = service.retrieve_patient_context("test query")

      expect(result).to include("Validated content")
      expect(result).not_to include("Not validated")
    end

    it "only includes embeddings for the specific account" do
      skip "Requires pgvector extension" unless pgvector_available?
      allow(service).to receive(:patient_rag_enabled?).and_return(true)
      other_account = create(:account)

      create(:health_embedding, account: account, content: "My content", embedding_type: "patient_message",
                                validated: true, embedding_array: [0.1] * 1536)
      create(:health_embedding, account: other_account, content: "Other content", embedding_type: "patient_message",
                                validated: true, embedding_array: [0.1] * 1536)

      result = service.retrieve_patient_context("test query")

      expect(result).to include("My content")
      expect(result).not_to include("Other content")
    end
  end

  describe "#retrieve_anonymized_patterns" do
    let(:mock_query_embedding) do
      instance_double(RubyLLM::Embedding, vectors: [0.1] * 1536)
    end

    before do
      allow(RubyLLM).to receive(:embed).and_return(mock_query_embedding)
    end

    it "returns nil when pattern_rag_enabled? is false" do
      allow(service).to receive(:pattern_rag_enabled?).and_return(false)

      result = service.retrieve_anonymized_patterns("test query")

      expect(result).to be_nil
    end

    it "returns embeddings of anonymized_pattern type" do
      skip "Requires pgvector extension" unless pgvector_available?
      allow(service).to receive(:pattern_rag_enabled?).and_return(true)

      create(:health_embedding, account: account, content: "Pattern 1", embedding_type: "anonymized_pattern",
                                validated: true, embedding_array: [0.1] * 1536)
      create(:health_embedding, account: account, content: "Patient msg", embedding_type: "patient_message",
                                validated: true, embedding_array: [0.1] * 1536)

      result = service.retrieve_anonymized_patterns("test query")

      expect(result.map(&:content)).to include("Pattern 1")
      expect(result.map(&:content)).not_to include("Patient msg")
    end

    it "returns validated patterns only" do
      skip "Requires pgvector extension" unless pgvector_available?
      allow(service).to receive(:pattern_rag_enabled?).and_return(true)

      create(:health_embedding, account: account, content: "Validated", embedding_type: "anonymized_pattern",
                                validated: true, embedding_array: [0.1] * 1536)
      create(:health_embedding, account: account, content: "Not validated", embedding_type: "anonymized_pattern",
                                validated: false, embedding_array: [0.1] * 1536)

      result = service.retrieve_anonymized_patterns("test query")

      expect(result.map(&:content)).to include("Validated")
      expect(result.map(&:content)).not_to include("Not validated")
    end

    it "limits to 5 patterns" do
      skip "Requires pgvector extension" unless pgvector_available?
      allow(service).to receive(:pattern_rag_enabled?).and_return(true)

      7.times do
        create(:health_embedding, account: account, embedding_type: "anonymized_pattern", validated: true,
                                  embedding_array: [0.1] * 1536)
      end

      result = service.retrieve_anonymized_patterns("test query")

      expect(result.count).to eq(5)
    end
  end

  describe "#patient_rag_enabled?" do
    it "defaults to true when no config set" do
      service = described_class.new(account: account)
      expect(service.patient_rag_enabled?).to be true
    end
  end

  describe "#pattern_rag_enabled?" do
    it "defaults to true when no config set" do
      service = described_class.new(account: account)
      expect(service.pattern_rag_enabled?).to be true
    end
  end
end
