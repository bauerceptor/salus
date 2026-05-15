require "rails_helper"

RSpec.describe SpecialistRequest, type: :model do
  describe "factory" do
    it { expect(build(:specialist_request)).to be_valid }
  end

  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:specialist).class_name("User") }
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[pending approved rejected]) }
  end

  describe "default status" do
    it "defaults to pending" do
      request = create(:specialist_request)
      expect(request.status).to eq("pending")
    end
  end

  describe "#approve!" do
    let(:request) { create(:specialist_request) }

    it "updates status to approved" do
      request.approve!
      expect(request.status).to eq("approved")
    end

    it "creates an active SpecialistPatient linking patient to specialist" do
      expect do
        request.approve!
      end.to change(SpecialistPatient, :count).by(1)

      sp = SpecialistPatient.last
      expect(sp.account_id).to eq(request.account_id)
      expect(sp.specialist_id).to eq(request.specialist_id)
      expect(sp.status).to eq("active")
      expect(sp.relationship_type).to eq("primary_care")
    end
  end

  describe "#reject!" do
    let(:request) { create(:specialist_request) }

    it "updates status to rejected" do
      request.reject!
      expect(request.status).to eq("rejected")
    end
  end
end
