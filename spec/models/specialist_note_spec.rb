require "rails_helper"

RSpec.describe SpecialistNote, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:specialist).class_name("User") }
    it { is_expected.to belong_to(:account) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:content) }
  end

  describe "scopes" do
    let(:specialist_user) { create(:user, :specialist) }
    let(:patient_account) { create(:account) }

    describe ".by_specialist" do
      it "returns notes for a specific specialist" do
        note = create(:specialist_note, specialist: specialist_user, account: patient_account)
        other_note = create(:specialist_note)
        expect(described_class.by_specialist(specialist_user)).to include(note)
        expect(described_class.by_specialist(specialist_user)).not_to include(other_note)
      end
    end

    describe ".for_patient" do
      it "returns notes for a specific patient" do
        note = create(:specialist_note, specialist: specialist_user, account: patient_account)
        other_note = create(:specialist_note, account: patient_account)
        expect(described_class.for_patient(patient_account)).to include(note)
        expect(described_class.for_patient(patient_account)).to include(other_note)
      end
    end
  end
end
