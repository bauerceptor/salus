# == Schema Information
#
# Table name: treatment_requests
#
#  id               :uuid             not null, primary key
#  account_id        :uuid             not null
#  description       :text             default(""), not null
#  rejection_reason  :text             default(""), not null
#  requested_at      :datetime         not null
#  reviewed_at       :datetime
#  specialist_id     :uuid
#  start_date        :date
#  status            :string           default("pending"), not null
#  title             :string           default(""), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
require "rails_helper"

RSpec.describe TreatmentRequest, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:specialist).class_name("User").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(100) }
    it { is_expected.to validate_length_of(:description).is_at_most(500) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[pending approved rejected]) }

    describe "start_date" do
      it { is_expected.to allow_value(Time.zone.today).for(:start_date) }
      it { is_expected.to allow_value(1.day.from_now).for(:start_date) }
      it { is_expected.to allow_value(3.days.from_now).for(:start_date) }
      it { is_expected.not_to allow_value(7.days.ago).for(:start_date) }
      it { is_expected.not_to allow_value(4.days.from_now).for(:start_date) }
    end
  end

  describe "scopes" do
    let_it_be(:pending_request) { create(:treatment_request, status: "pending") }
    let_it_be(:approved_request) { create(:treatment_request, status: "approved") }
    let_it_be(:rejected_request) { create(:treatment_request, status: "rejected") }

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

    describe ".for_account" do
      let_it_be(:account) { create(:account) }
      let_it_be(:own_request) { create(:treatment_request, account: account) }
      let_it_be(:other_request) { create(:treatment_request) }

      it "returns requests for specified account" do
        expect(described_class.for_account(account)).to include(own_request)
        expect(described_class.for_account(account)).not_to include(other_request)
      end
    end

    describe ".recent_pending" do
      it "returns pending requests from last 30 days" do
        recent_request = create(:treatment_request, status: "pending", requested_at: 1.day.ago)
        old_request = create(:treatment_request, status: "pending", requested_at: 60.days.ago)
        results = described_class.recent_pending
        expect(results).to include(recent_request)
        expect(results).not_to include(old_request)
      end
    end
  end

  describe "#pending?" do
    let_it_be(:request) { create(:treatment_request, status: "pending") }

    it "returns true when status is pending" do
      expect(request.pending?).to be true
    end

    it "returns false when status is not pending" do
      request.status = "approved"
      expect(request.pending?).to be false
    end
  end

  describe "#approved?" do
    let_it_be(:request) { create(:treatment_request, status: "approved") }

    it "returns true when status is approved" do
      expect(request.approved?).to be true
    end

    it "returns false when status is not approved" do
      request.status = "pending"
      expect(request.approved?).to be false
    end
  end

  describe "#rejected?" do
    let_it_be(:request) { create(:treatment_request, status: "rejected") }

    it "returns true when status is rejected" do
      expect(request.rejected?).to be true
    end

    it "returns false when status is not rejected" do
      request.status = "pending"
      expect(request.rejected?).to be false
    end
  end

  describe "#approve!" do
    let_it_be(:request) { create(:treatment_request, status: "pending") }
    let_it_be(:specialist) { create(:user, :specialist) }

    it "updates status to approved" do
      request.approve!(specialist)
      expect(request.status).to eq("approved")
    end

    it "sets specialist_id" do
      request.approve!(specialist)
      expect(request.specialist_id).to eq(specialist.id)
    end

    it "sets reviewed_at timestamp" do
      request.approve!(specialist)
      expect(request.reviewed_at).to be_present
    end
  end

  describe "#reject!" do
    let_it_be(:request) { create(:treatment_request, status: "pending") }
    let_it_be(:specialist) { create(:user, :specialist) }

    it "updates status to rejected" do
      request.reject!(specialist)
      expect(request.status).to eq("rejected")
    end

    it "sets specialist_id" do
      request.reject!(specialist)
      expect(request.specialist_id).to eq(specialist.id)
    end

    it "accepts rejection reason" do
      request.reject!(specialist, "Not appropriate for patient condition")
      expect(request.rejection_reason).to eq("Not appropriate for patient condition")
    end

    it "sets reviewed_at timestamp" do
      request.reject!(specialist)
      expect(request.reviewed_at).to be_present
    end
  end

  describe "before_validation callback" do
    describe "#set_defaults" do
      it "sets status to pending by default" do
        request = build(:treatment_request, status: nil)
        request.valid?
        expect(request.status).to eq("pending")
      end

      it "sets requested_at to current time" do
        request = create(:treatment_request)
        expect(request.requested_at).to be_present
      end
    end
  end
end
