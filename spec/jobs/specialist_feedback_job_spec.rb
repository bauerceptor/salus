require "rails_helper"

RSpec.describe SpecialistFeedbackJob, type: :job do
  describe "#perform" do
    let(:account) { create(:account) }
    let(:specialist) { create(:user, account: create(:account, first_name: "Dr", last_name: "Smith")) }
    let(:emergency_alert) do
      create(:emergency_alert,
             account: account,
             alert_type: "low_adherence",
             message: "Patient adherence dropping",
             status: "pending")
    end

    before do
      mock_embedding_result = instance_double(RubyLLM::Embedding, vectors: Array.new(1536, 0.02))
      allow(RubyLLM).to receive(:embed).and_return(mock_embedding_result)
    end

    context "when action is 'confirmed'" do
      it "creates an embedding with confirmed feedback context" do
        expect do
          described_class.perform_now(emergency_alert.id, "confirmed")
        end.to change(HealthEmbedding, :count).by(1)

        embedding = HealthEmbedding.last
        expect(embedding.content).to include("confirmed")
        expect(embedding.content).to include(emergency_alert.alert_type)
      end

      it "sets embedding_type to anonymized_pattern" do
        described_class.perform_now(emergency_alert.id, "confirmed")
        embedding = HealthEmbedding.last
        expect(embedding.embedding_type).to eq("anonymized_pattern")
      end

      it "stores alert metadata" do
        described_class.perform_now(emergency_alert.id, "confirmed")
        embedding = HealthEmbedding.last
        expect(embedding.metadata["alert_type"]).to eq("low_adherence")
        expect(embedding.metadata["action"]).to eq("confirmed")
      end
    end

    context "when action is 'corrected'" do
      it "creates an embedding with corrected feedback context" do
        expect do
          described_class.perform_now(emergency_alert.id, "corrected")
        end.to change(HealthEmbedding, :count).by(1)

        embedding = HealthEmbedding.last
        expect(embedding.content).to include("corrected")
      end
    end

    context "when action is 'ignored'" do
      it "creates an embedding with ignored feedback context" do
        expect do
          described_class.perform_now(emergency_alert.id, "ignored")
        end.to change(HealthEmbedding, :count).by(1)
      end
    end

    context "when action is 'dismissed'" do
      it "creates an embedding with dismissed feedback context" do
        expect do
          described_class.perform_now(emergency_alert.id, "dismissed")
        end.to change(HealthEmbedding, :count).by(1)
      end
    end

    context "when emergency_alert does not exist" do
      it "does not raise an error" do
        expect do
          described_class.perform_now(99_999, "confirmed")
        end.not_to raise_error
      end

      it "does not create any embedding" do
        expect do
          described_class.perform_now(99_999, "confirmed")
        end.not_to change(HealthEmbedding, :count)
      end
    end

    context "when nil is passed" do
      it "does not raise an error" do
        expect do
          described_class.perform_now(nil, "confirmed")
        end.not_to raise_error
      end
    end
  end
end
