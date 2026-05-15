require "rails_helper"

RSpec.describe Notification, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:notifiable).optional(true) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:notification_type) }
  end

  describe "scopes" do
    let(:account) { create(:account) }
    let!(:unread_notification) { create(:notification, account: account, read_at: nil) }
    let!(:read_notification) { create(:notification, account: account, read_at: Time.current) }

    describe ".unread" do
      it "returns only unread notifications" do
        expect(described_class.unread).to include(unread_notification)
        expect(described_class.unread).not_to include(read_notification)
      end
    end

    describe ".read" do
      it "returns only read notifications" do
        expect(described_class.read).to include(read_notification)
        expect(described_class.read).not_to include(unread_notification)
      end
    end

    describe ".for_account" do
      it "returns notifications for a specific account" do
        other_account = create(:account)
        other_notification = create(:notification, account: other_account)
        expect(described_class.for_account(account)).to include(unread_notification)
        expect(described_class.for_account(account)).not_to include(other_notification)
      end
    end

    describe ".recent" do
      it "limits to 50 notifications" do
        create_list(:notification, 55, account: account)
        expect(described_class.recent.count).to eq(50)
      end

      it "orders by created_at desc" do
        create(:notification, account: account, created_at: 1.day.ago)
        newer = create(:notification, account: account, created_at: Time.current)
        expect(described_class.recent.first).to eq(newer)
      end
    end
  end

  describe "#mark_as_read" do
    let(:notification) { create(:notification, read_at: nil) }

    it "marks the notification as read" do
      expect do
        notification.mark_as_read
      end.to change(notification, :read_at).from(nil)
    end

    it "does not update if already read" do
      notification.update(read_at: Time.current)
      expect do
        notification.mark_as_read
      end.not_to change(notification, :read_at)
    end
  end

  describe "#unread?" do
    it "returns true if read_at is nil" do
      notification = create(:notification, read_at: nil)
      expect(notification.unread?).to be true
    end

    it "returns false if read_at is set" do
      notification = create(:notification, read_at: Time.current)
      expect(notification.unread?).to be false
    end
  end
end
