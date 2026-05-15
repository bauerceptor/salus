require "rails_helper"

RSpec.describe KnowledgeDistillationJob, type: :job do
  describe "#perform" do
    let(:account) { create(:account, first_name: "Alice", last_name: "Patient") }
    let(:specialist) { create(:user, account: create(:account, first_name: "Bob", last_name: "Doctor")) }
    let(:specialist_message) do
      create(:specialist_message,
             account: account,
             specialist: specialist,
             sender_type: "patient",
             body: "Alice has been experiencing increased fatigue and dizziness. Bob Doctor recommended I rest.")
    end

    before do
      mock_embedding_result = instance_double(RubyLLM::Embedding, vectors: Array.new(1536, 0.01))
      allow(RubyLLM).to receive(:embed).and_return(mock_embedding_result)
    end

    context "when message is from patient" do
      it "enqueues a job" do
        expect do
          described_class.perform_later(specialist_message.id)
        end.to have_enqueued_job(described_class).with(specialist_message.id)
      end

      it "creates an anonymized_pattern embedding" do
        expect do
          described_class.perform_now(specialist_message.id)
        end.to change(HealthEmbedding, :count).by(1)
      end

      it "replaces patient name with [Patient]" do
        described_class.perform_now(specialist_message.id)
        embedding = HealthEmbedding.last
        expect(embedding.content).not_to include("Alice")
        expect(embedding.content).to include("[Patient]")
      end

      it "replaces specialist name with [Specialist]" do
        described_class.perform_now(specialist_message.id)
        embedding = HealthEmbedding.last
        expect(embedding.content).not_to include("Bob")
        expect(embedding.content).not_to include("Doctor")
        expect(embedding.content).to include("[Specialist]")
      end

      it "sets embedding_type to anonymized_pattern" do
        described_class.perform_now(specialist_message.id)
        embedding = HealthEmbedding.last
        expect(embedding.embedding_type).to eq("anonymized_pattern")
      end

      it "sets account to message account" do
        described_class.perform_now(specialist_message.id)
        embedding = HealthEmbedding.last
        expect(embedding.account).to eq(account)
      end

      it "stores metadata with specialist_id and sender_type" do
        described_class.perform_now(specialist_message.id)
        embedding = HealthEmbedding.last
        expect(embedding.metadata["specialist_id"]).to eq(specialist.id)
        expect(embedding.metadata["sender_type"]).to eq("patient")
        expect(embedding.metadata["message_type"]).to be_present
      end
    end

    context "when message is from specialist" do
      let(:specialist_message) do
        create(:specialist_message,
               account: account,
               specialist: specialist,
               sender_type: "specialist",
               body: "Bob Doctor should monitor fluid intake and rest for a few days.")
      end

      it "replaces specialist name with [Specialist]" do
        described_class.perform_now(specialist_message.id)
        embedding = HealthEmbedding.last
        expect(embedding.content).not_to include("Bob")
        expect(embedding.content).to include("[Specialist]")
      end

      it "still creates an anonymized pattern embedding" do
        expect do
          described_class.perform_now(specialist_message.id)
        end.to change(HealthEmbedding, :count).by(1)
      end
    end

    context "when message body is too short" do
      let(:specialist_message) do
        create(:specialist_message,
               account: account,
               specialist: specialist,
               sender_type: "patient",
               body: "Hi")
      end

      it "does not create an embedding" do
        expect do
          described_class.perform_now(specialist_message.id)
        end.not_to change(HealthEmbedding, :count)
      end
    end

    context "when specialist_message does not exist" do
      it "does not raise an error" do
        expect do
          described_class.perform_now(99_999)
        end.not_to raise_error
      end

      it "does not create any embedding" do
        expect do
          described_class.perform_now(99_999)
        end.not_to change(HealthEmbedding, :count)
      end
    end

    context "when nil is passed" do
      it "does not raise an error" do
        expect do
          described_class.perform_now(nil)
        end.not_to raise_error
      end
    end
  end
end
