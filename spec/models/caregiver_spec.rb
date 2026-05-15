require "rails_helper"

RSpec.describe Caregiver, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:caregiver_account).class_name("Account") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:relationship) }

    it "validates uniqueness of account_id scoped to caregiver_account_id" do
      account = create(:account)
      caregiver_account = create(:account)
      create(:caregiver, account: account, caregiver_account: caregiver_account)
      expect do
        create(:caregiver, account: account, caregiver_account: caregiver_account)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "scopes" do
    describe ".accepted" do
      it "returns only accepted caregivers" do
        accepted = create(:caregiver, is_accepted: true)
        pending = create(:caregiver, is_accepted: false)
        expect(described_class.accepted).to include(accepted)
        expect(described_class.accepted).not_to include(pending)
      end
    end

    describe ".pending" do
      it "returns only pending caregivers" do
        pending = create(:caregiver, is_accepted: false)
        accepted = create(:caregiver, is_accepted: true)
        expect(described_class.pending).to include(pending)
        expect(described_class.pending).not_to include(accepted)
      end
    end

    describe ".for_caregiver" do
      it "returns relationships for a specific caregiver account" do
        caregiver_account = create(:account)
        relationship = create(:caregiver, caregiver_account: caregiver_account)
        other = create(:caregiver)
        expect(described_class.for_caregiver(caregiver_account)).to include(relationship)
        expect(described_class.for_caregiver(caregiver_account)).not_to include(other)
      end
    end

    describe ".for_patient" do
      it "returns relationships for a specific patient account" do
        patient_account = create(:account)
        relationship = create(:caregiver, account: patient_account)
        other = create(:caregiver)
        expect(described_class.for_patient(patient_account)).to include(relationship)
        expect(described_class.for_patient(patient_account)).not_to include(other)
      end
    end
  end

  describe "#accept" do
    it "sets is_accepted to true" do
      caregiver = create(:caregiver, is_accepted: false)
      caregiver.accept
      expect(caregiver.is_accepted).to be true
    end
  end

  describe "#revoke" do
    it "sets is_accepted to false" do
      caregiver = create(:caregiver, is_accepted: true)
      caregiver.revoke
      expect(caregiver.is_accepted).to be false
    end
  end
end
