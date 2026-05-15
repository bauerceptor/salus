require "rails_helper"

RSpec.describe SpecialistRecommendation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:specialist).class_name("User") }
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:medication).optional }
    it { is_expected.to belong_to(:treatment).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_inclusion_of(:recommendation_type).in_array(%w[medication treatment]) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[pending accepted rejected dismissed]) }
  end

  describe "scopes" do
    let(:specialist_user) { create(:user, :specialist) }
    let(:patient_account) { create(:account) }

    describe ".pending" do
      it "returns only pending recommendations" do
        pending_rec = create(:specialist_recommendation, specialist: specialist_user, account: patient_account,
                                                         status: "pending")
        accepted_rec = create(:specialist_recommendation, specialist: specialist_user, account: patient_account,
                                                          status: "accepted")
        expect(described_class.pending).to include(pending_rec)
        expect(described_class.pending).not_to include(accepted_rec)
      end
    end

    describe ".accepted" do
      it "returns only accepted recommendations" do
        accepted_rec = create(:specialist_recommendation, specialist: specialist_user, account: patient_account,
                                                          status: "accepted")
        pending_rec = create(:specialist_recommendation, specialist: specialist_user, account: patient_account,
                                                         status: "pending")
        expect(described_class.accepted).to include(accepted_rec)
        expect(described_class.accepted).not_to include(pending_rec)
      end
    end

    describe ".for_patient" do
      it "returns recommendations for a specific patient" do
        rec = create(:specialist_recommendation, specialist: specialist_user, account: patient_account)
        other_rec = create(:specialist_recommendation, account: patient_account)
        expect(described_class.for_patient(patient_account)).to include(rec)
        expect(described_class.for_patient(patient_account)).to include(other_rec)
      end
    end
  end

  describe "#pending?" do
    it "returns true if status is pending" do
      rec = create(:specialist_recommendation, status: "pending")
      expect(rec.pending?).to be true
    end

    it "returns false if status is not pending" do
      rec = create(:specialist_recommendation, status: "accepted")
      expect(rec.pending?).to be false
    end
  end

  describe "#accept!" do
    it "updates status to accepted" do
      rec = create(:specialist_recommendation, status: "pending")
      rec.accept!
      expect(rec.status).to eq("accepted")
    end
  end

  describe "#reject!" do
    it "updates status to rejected" do
      rec = create(:specialist_recommendation, status: "pending")
      rec.reject!
      expect(rec.status).to eq("rejected")
    end
  end

  describe "#accept!" do
    context "for treatment recommendation" do
      let(:specialist_user) { create(:user, :specialist) }
      let(:patient_account) { create(:account) }

      it "creates a Treatment linked to the recommendation" do
        rec = create(:specialist_recommendation,
                     specialist: specialist_user,
                     account: patient_account,
                     recommendation_type: "treatment",
                     name: "Physical Therapy",
                     notes: "3 times per week",
                     status: "pending")

        expect do
          rec.accept!
        end.to change(Treatment, :count).by(1)

        treatment = Treatment.last
        expect(treatment.account).to eq(patient_account)
        expect(treatment.specialist_recommendation_id).to eq(rec.id)
        expect(treatment.source).to eq("doctor_prescription")
        expect(treatment.title).to eq("Physical Therapy")
        expect(treatment.description).to eq("3 times per week")
        expect(treatment.approval_status).to eq("approved")
        expect(treatment.approved_by_id).to eq(specialist_user.id)
      end

      it "updates recommendation status to accepted" do
        rec = create(:specialist_recommendation,
                     specialist: specialist_user,
                     account: patient_account,
                     recommendation_type: "treatment",
                     status: "pending")
        rec.accept!
        expect(rec.status).to eq("accepted")
      end
    end

    context "for medication recommendation" do
      let(:specialist_user) { create(:user, :specialist) }
      let(:patient_account) { create(:account) }

      it "creates a Medication linked to the recommendation" do
        rec = create(:specialist_recommendation,
                     specialist: specialist_user,
                     account: patient_account,
                     recommendation_type: "medication",
                     name: "Metformin",
                     dosage: "500mg",
                     status: "pending")

        expect do
          rec.accept!
        end.to change(Medication, :count).by(1)

        medication = Medication.last
        expect(medication.account).to eq(patient_account)
        expect(medication.name).to eq("Metformin")
        expect(medication.dosage).to eq("500mg")
        expect(medication.is_active).to be true
        expect(medication.source).to eq("doctor_prescription")
        expect(medication.specialist_recommendation_id).to eq(rec.id)
      end

      it "updates recommendation status to accepted" do
        rec = create(:specialist_recommendation,
                     specialist: specialist_user,
                     account: patient_account,
                     recommendation_type: "medication",
                     status: "pending")
        rec.accept!
        expect(rec.status).to eq("accepted")
      end
    end
  end

  describe "#treatment?" do
    it "returns true for treatment recommendation" do
      rec = create(:specialist_recommendation, recommendation_type: "treatment")
      expect(rec.treatment?).to be true
    end

    it "returns false for medication recommendation" do
      rec = create(:specialist_recommendation, recommendation_type: "medication")
      expect(rec.treatment?).to be false
    end
  end

  describe "#medication?" do
    it "returns true for medication recommendation" do
      rec = create(:specialist_recommendation, recommendation_type: "medication")
      expect(rec.medication?).to be true
    end

    it "returns false for treatment recommendation" do
      rec = create(:specialist_recommendation, recommendation_type: "treatment")
      expect(rec.medication?).to be false
    end
  end
end
