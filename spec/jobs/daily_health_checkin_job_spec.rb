require "rails_helper"

RSpec.describe DailyHealthCheckinJob, type: :job do
  describe "#perform" do
    let(:account) { create(:account, first_name: "James", last_name: "Dean") }
    let(:user) { account.user }

    before do
      create(:medication, account: account, name: "Ursodeoxycholic Acid", is_active: true)
    end

    it "creates a health agent message for the patient" do
      expect do
        described_class.perform_now
      end.to change(HealthAgentMessage, :count).by(1)
    end

    it "creates a health agent conversation if none exists" do
      expect do
        described_class.perform_now
      end.to change(HealthAgentConversation, :count).by(1)
    end

    it "uses existing conversation if one already exists" do
      create(:health_agent_conversation, account: account, persona: :patient, status: :active)

      expect do
        described_class.perform_now
      end.to change(HealthAgentConversation, :count).by(0)
    end

    it "does not process accounts without medications or measurements" do
      allow(Account).to receive(:find_each).and_yield(account)

      expect do
        described_class.perform_now
      end.to change(HealthAgentMessage, :count).by(1)
    end

    it "does not crash when OpenAI returns an error" do
      allow(ProactiveAgentService).to receive(:call).and_return(nil)

      expect do
        described_class.perform_now
      end.not_to raise_error
    end

    it "broadcasts notification to the account" do
      allow(NotificationsChannel).to receive(:broadcast_to)

      described_class.perform_now

      expect(NotificationsChannel).to have_received(:broadcast_to).with(
        account,
        hash_including(type: "proactive_checkin")
      )
    end
  end
end