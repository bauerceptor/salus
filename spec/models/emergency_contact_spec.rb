require "rails_helper"

RSpec.describe EmergencyContact, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:phone_number) }
    it { is_expected.to validate_presence_of(:relationship) }
  end

  describe "scopes" do
    let(:account) { create(:account) }

    describe ".for_account" do
      it "returns contacts for a specific account" do
        contact = create(:emergency_contact, account: account)
        other_contact = create(:emergency_contact)
        expect(described_class.for_account(account)).to include(contact)
        expect(described_class.for_account(account)).not_to include(other_contact)
      end
    end

    describe ".notifyable" do
      it "returns only notifyable contacts" do
        notifyable = create(:emergency_contact, account: account, notify_on_emergency: true)
        non_notifyable = create(:emergency_contact, account: account, notify_on_emergency: false)
        expect(described_class.notifyable).to include(notifyable)
        expect(described_class.notifyable).not_to include(non_notifyable)
      end
    end
  end
end
