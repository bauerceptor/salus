require "rails_helper"

RSpec.describe WeeklyProgressSummaryJob, type: :job do
  describe "#perform" do
    let(:account) { create(:account, first_name: "James", last_name: "Dean") }

    before do
      create(:medication, account: account, is_active: true)
    end

    context "when account has recent medication logs" do
      before do
        create(:medication_log, account: account, status: :taken, scheduled_for: 2.days.ago)
        create(:medication_log, account: account, status: :taken, scheduled_for: 1.day.ago)
        create(:medication_log, account: account, status: :missed, scheduled_for: Time.current)
      end

      it "creates a health agent message" do
        expect do
          described_class.perform_now
        end.to change(HealthAgentMessage, :count).by(1)
      end
    end

    context "when account has recent measurements" do
      before do
        weight_type = create(:weight_measurement_type)
        create(:measurement, account: account, measurement_type: weight_type, value: "75", measurement_date: 1.day.ago)
        create(:measurement, account: account, measurement_type: weight_type, value: "74", measurement_date: 2.days.ago)
      end

      it "creates a health agent message" do
        expect do
          described_class.perform_now
        end.to change(HealthAgentMessage, :count).by(1)
      end
    end

    context "when account has no recent activity" do
      it "does not create a message" do
        expect do
          described_class.perform_now
        end.not_to change(HealthAgentMessage, :count)
      end
    end

    it "does not crash when OpenAI returns an error" do
      allow(ProactiveAgentService).to receive(:call).and_return(nil)

      create(:medication_log, account: account, status: :taken, scheduled_for: 1.day.ago)

      expect do
        described_class.perform_now
      end.not_to raise_error
    end

    it "broadcasts notification with weekly_summary type" do
      allow(NotificationsChannel).to receive(:broadcast_to)

      create(:medication_log, account: account, status: :taken, scheduled_for: 1.day.ago)
      described_class.perform_now

      expect(NotificationsChannel).to have_received(:broadcast_to).with(
        account,
        hash_including(type: "weekly_summary")
      )
    end
  end
end
