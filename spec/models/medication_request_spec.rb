require "rails_helper"

RSpec.describe MedicationRequest, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:specialist).class_name("User").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:medication_name) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[pending approved rejected]) }
  end

  describe "scopes" do
    let_it_be(:pending_request) { create(:medication_request, status: "pending") }
    let_it_be(:approved_request) { create(:medication_request, status: "approved") }
    let_it_be(:rejected_request) { create(:medication_request, status: "rejected") }

    describe ".pending" do
      it "returns only pending requests" do
        expect(described_class.pending).to include(pending_request)
        expect(described_class.pending).not_to include(approved_request, rejected_request)
      end
    end

    describe ".approved" do
      it "returns only approved requests" do
        expect(described_class.approved).to include(approved_request)
        expect(described_class.approved).not_to include(pending_request, rejected_request)
      end
    end

    describe ".rejected" do
      it "returns only rejected requests" do
        expect(described_class.rejected).to include(rejected_request)
        expect(described_class.rejected).not_to include(pending_request, approved_request)
      end
    end

    describe ".for_specialist" do
      let_it_be(:specialist) { create(:user, :specialist) }
      let_it_be(:own_request) { create(:medication_request, specialist: specialist) }
      let_it_be(:other_request) { create(:medication_request) }

      it "returns requests for specified specialist" do
        expect(described_class.for_specialist(specialist)).to include(own_request)
        expect(described_class.for_specialist(specialist)).not_to include(other_request)
      end
    end
  end

  describe "#pending?" do
    let_it_be(:request) { create(:medication_request, status: "pending") }

    it "returns true when status is pending" do
      expect(request.pending?).to be true
    end

    it "returns false when status is not pending" do
      request.status = "approved"
      expect(request.pending?).to be false
    end
  end

  describe "#approved?" do
    let_it_be(:request) { create(:medication_request, status: "approved") }

    it "returns true when status is approved" do
      expect(request.approved?).to be true
    end

    it "returns false when status is not approved" do
      request.status = "pending"
      expect(request.approved?).to be false
    end
  end

  describe "#rejected?" do
    let_it_be(:request) { create(:medication_request, status: "rejected") }

    it "returns true when status is rejected" do
      expect(request.rejected?).to be true
    end

    it "returns false when status is not rejected" do
      request.status = "pending"
      expect(request.rejected?).to be false
    end
  end

  describe "#approve!" do
    let_it_be(:request) { create(:medication_request, status: "pending") }
    let_it_be(:specialist) { create(:user, :specialist) }

    it "updates status to approved" do
      request.approve!
      expect(request.status).to eq("approved")
    end

    it "sets reviewed_at timestamp" do
      request.approve!
      expect(request.reviewed_at).to be_present
    end
  end

  describe "#reject!" do
    let_it_be(:request) { create(:medication_request, status: "pending") }
    let_it_be(:specialist) { create(:user, :specialist) }

    it "updates status to rejected" do
      request.reject!
      expect(request.status).to eq("rejected")
    end

    it "sets reviewed_at timestamp" do
      request.reject!
      expect(request.reviewed_at).to be_present
    end

    it "accepts rejection reason" do
      request.reject!("Not appropriate for patient condition")
      expect(request.rejection_reason).to eq("Not appropriate for patient condition")
    end
  end

  describe "before_validation callback" do
    describe "#set_defaults" do
      it "sets status to pending by default" do
        request = build(:medication_request, status: nil)
        request.valid?
        expect(request.status).to eq("pending")
      end

      it "sets requested_at to current time" do
        request = create(:medication_request)
        expect(request.requested_at).to be_present
      end
    end
  end
end
