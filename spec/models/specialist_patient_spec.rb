require "rails_helper"

RSpec.describe SpecialistPatient, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:specialist).class_name("User") }
    it { is_expected.to belong_to(:account) }
  end

  describe "scopes" do
    let(:specialist_user) { create(:user, :specialist) }
    let(:patient_account) { create(:account) }

    describe ".active" do
      it "returns only active specialist patients" do
        active_sp = create(:specialist_patient, specialist: specialist_user, account: patient_account, status: "active")
        pending_sp = create(:specialist_patient, specialist: specialist_user, status: "pending")
        expect(described_class.active).to include(active_sp)
        expect(described_class.active).not_to include(pending_sp)
      end
    end

    describe ".pending" do
      it "returns only pending specialist patients" do
        pending_sp = create(:specialist_patient, specialist: specialist_user, account: patient_account,
                                                 status: "pending")
        active_sp = create(:specialist_patient, specialist: specialist_user, status: "active")
        expect(described_class.pending).to include(pending_sp)
        expect(described_class.pending).not_to include(active_sp)
      end
    end
  end

  describe "#active?" do
    it "returns true when status is active" do
      sp = create(:specialist_patient, status: "active")
      expect(sp.active?).to be true
    end

    it "returns false when status is not active" do
      sp = create(:specialist_patient, status: "inactive")
      expect(sp.active?).to be false
    end
  end
end
