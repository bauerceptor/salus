require "rails_helper"

RSpec.describe EmergencyAlert, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:emergency_contact).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:alert_type) }
  end

  describe "scopes" do
    let(:account) { create(:account) }

    describe ".active" do
      it "returns only active alerts" do
        active = create(:emergency_alert, account: account, status: 0)
        resolved = create(:emergency_alert, account: account, status: 3)
        expect(described_class.active).to include(active)
        expect(described_class.active).not_to include(resolved)
      end
    end

    describe ".for_account" do
      it "returns alerts for a specific account" do
        alert = create(:emergency_alert, account: account)
        other_alert = create(:emergency_alert)
        expect(described_class.for_account(account)).to include(alert)
        expect(described_class.for_account(account)).not_to include(other_alert)
      end
    end
  end

  describe "#acknowledge" do
    it "updates status to acknowledged" do
      alert = create(:emergency_alert, status: 0)
      alert.acknowledge
      expect(alert.status).to eq(2)
      expect(alert.acknowledged_at).to be_present
    end
  end

  describe "#resolve" do
    it "updates status to resolved" do
      alert = create(:emergency_alert, status: 0)
      alert.resolve
      expect(alert.status).to eq(3)
    end
  end
end
