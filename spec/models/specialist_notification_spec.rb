require "rails_helper"

RSpec.describe SpecialistNotification, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:specialist).class_name("User") }
    it { is_expected.to belong_to(:patient).class_name("Account") }
    it { is_expected.to belong_to(:notifiable).optional(true) }
  end

  describe "scopes" do
    let(:specialist_user) { create(:user, :specialist) }
    let(:patient_account) { create(:account) }

    describe ".for_specialist" do
      it "returns notifications for a specific specialist" do
        notification = create(:specialist_notification, specialist: specialist_user, patient: patient_account)
        other_notification = create(:specialist_notification)
        expect(described_class.for_specialist(specialist_user)).to include(notification)
        expect(described_class.for_specialist(specialist_user)).not_to include(other_notification)
      end
    end

    describe ".unread" do
      it "returns only unread notifications" do
        unread = create(:specialist_notification, specialist: specialist_user, patient: patient_account, is_read: false)
        read = create(:specialist_notification, specialist: specialist_user, patient: patient_account, is_read: true)
        expect(described_class.unread).to include(unread)
        expect(described_class.unread).not_to include(read)
      end
    end

    describe ".unacknowledged" do
      it "returns only unacknowledged notifications" do
        unacknowledged = create(:specialist_notification, specialist: specialist_user, patient: patient_account,
                                                          acknowledged_at: nil)
        acknowledged = create(:specialist_notification, specialist: specialist_user, patient: patient_account,
                                                        acknowledged_at: Time.current)
        expect(described_class.unacknowledged).to include(unacknowledged)
        expect(described_class.unacknowledged).not_to include(acknowledged)
      end
    end

    describe ".critical" do
      it "returns only critical type notifications" do
        critical = create(:specialist_notification, specialist: specialist_user, patient: patient_account,
                                                    notification_type: "sos_alert")
        other = create(:specialist_notification, specialist: specialist_user, patient: patient_account,
                                                 notification_type: "new_message")
        expect(described_class.critical).to include(critical)
        expect(described_class.critical).not_to include(other)
      end
    end

    describe ".warning" do
      it "returns only warning type notifications" do
        warning = create(:specialist_notification, specialist: specialist_user, patient: patient_account,
                                                   notification_type: "missed_medication")
        other = create(:specialist_notification, specialist: specialist_user, patient: patient_account,
                                                 notification_type: "new_message")
        expect(described_class.warning).to include(warning)
        expect(described_class.warning).not_to include(other)
      end
    end

    describe ".info" do
      it "returns only info type notifications" do
        info = create(:specialist_notification, specialist: specialist_user, patient: patient_account,
                                                notification_type: "new_message")
        other = create(:specialist_notification, specialist: specialist_user, patient: patient_account,
                                                 notification_type: "sos_alert")
        expect(described_class.info).to include(info)
        expect(described_class.info).not_to include(other)
      end
    end
  end

  describe "#mark_as_read!" do
    let(:notification) { create(:specialist_notification, is_read: false) }

    it "marks the notification as read" do
      expect do
        notification.mark_as_read!
      end.to change(notification, :is_read).from(false).to(true)
    end
  end

  describe "#acknowledge!" do
    let(:specialist_user) { create(:user, :specialist) }
    let(:patient_account) { create(:account) }
    let!(:specialist_patient) do
      create(:specialist_patient, specialist: specialist_user, account: patient_account, status: "active")
    end
    let(:notification) do
      create(:specialist_notification, specialist: specialist_user, patient: patient_account, acknowledged_at: nil)
    end

    it "marks the notification as acknowledged" do
      expect do
        notification.acknowledge!(specialist: specialist_user)
      end.to change(notification, :acknowledged_at).from(nil)
    end

    it "raises ArgumentError when specialist is not authorized" do
      other_specialist = create(:user, :specialist)
      expect do
        notification.acknowledge!(specialist: other_specialist)
      end.to raise_error(ArgumentError, "Not authorized")
    end
  end

  describe "#acknowledged?" do
    it "returns true when acknowledged_at is set" do
      notification = create(:specialist_notification, acknowledged_at: Time.current)
      expect(notification.acknowledged?).to be true
    end

    it "returns false when acknowledged_at is nil" do
      notification = create(:specialist_notification, acknowledged_at: nil)
      expect(notification.acknowledged?).to be false
    end
  end

  describe "#severity" do
    it "returns :critical for sos_alert" do
      notification = create(:specialist_notification, notification_type: "sos_alert")
      expect(notification.severity).to eq(:critical)
    end

    it "returns :critical for abnormal_measurement" do
      notification = create(:specialist_notification, notification_type: "abnormal_measurement")
      expect(notification.severity).to eq(:critical)
    end

    it "returns :warning for missed_medication" do
      notification = create(:specialist_notification, notification_type: "missed_medication")
      expect(notification.severity).to eq(:warning)
    end

    it "returns :warning for low_adherence" do
      notification = create(:specialist_notification, notification_type: "low_adherence")
      expect(notification.severity).to eq(:warning)
    end

    it "returns :info for new_message" do
      notification = create(:specialist_notification, notification_type: "new_message")
      expect(notification.severity).to eq(:info)
    end

    it "returns :info for recommendation_response" do
      notification = create(:specialist_notification, notification_type: "recommendation_response")
      expect(notification.severity).to eq(:info)
    end
  end
end
