require "rails_helper"

RSpec.describe MissedDoseFollowupJob, type: :job do
  describe "#perform" do
    let(:account) { create(:account, first_name: "James", last_name: "Dean") }
    let(:medication) { create(:medication, account: account, name: "Ursodeoxycholic Acid", is_active: true) }

    context "when there are missed doses within the window" do
      before do
        create(:medication_log, account: account, medication: medication, status: :missed, scheduled_for: 1.hour.ago)
      end

      it "creates a health agent message" do
        expect do
          described_class.perform_now
        end.to change(HealthAgentMessage, :count).by(1)
      end

      it "creates a health agent conversation if none exists" do
        expect do
          described_class.perform_now
        end.to change(HealthAgentConversation, :count).by(1)
      end

      it "does not process the same missed dose twice within one run" do
        allow(ProactiveAgentService).to receive(:call).and_return("Test message")

        described_class.perform_now

        expect(ProactiveAgentService).to have_received(:call).once
      end
    end

    context "when missed dose is outside the window" do
      before do
        create(:medication_log, account: account, medication: medication, status: :missed, scheduled_for: 10.hours.ago)
      end

      it "does not create a message" do
        expect do
          described_class.perform_now
        end.not_to change(HealthAgentMessage, :count)
      end
    end

    context "when there are no missed doses" do
      before do
        create(:medication_log, account: account, medication: medication, status: :taken, scheduled_for: 1.hour.ago)
      end

      it "does not create a message" do
        expect do
          described_class.perform_now
        end.not_to change(HealthAgentMessage, :count)
      end
    end

    it "does not crash when OpenAI returns an error" do
      create(:medication_log, account: account, medication: medication, status: :missed, scheduled_for: 1.hour.ago)
      allow(ProactiveAgentService).to receive(:call).and_return(nil)

      expect do
        described_class.perform_now
      end.not_to raise_error
    end

    it "broadcasts notification with missed_dose_followup type" do
      create(:medication_log, account: account, medication: medication, status: :missed, scheduled_for: 1.hour.ago)
      allow(NotificationsChannel).to receive(:broadcast_to)

      described_class.perform_now

      expect(NotificationsChannel).to have_received(:broadcast_to).with(
        account,
        hash_including(type: "missed_dose_followup")
      )
    end
  end
end
