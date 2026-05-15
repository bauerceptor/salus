require "rails_helper"

RSpec.describe DiseaseOnboardingService do
  let(:account) { create(:account) }
  let(:predefined_disease) { create(:predefined_disease) }
  let(:disease) { create(:disease, account: account, predefined_disease: predefined_disease) }

  describe "#group" do
    it "returns the group associated with the disease's predefined disease" do
      service = described_class.new(disease, account)
      expect(service.group).to eq(predefined_disease.group)
    end

    it "returns nil if predefined disease has no group" do
      predefined_disease_no_group = create(:predefined_disease, :no_group)
      disease_no_group = create(:disease, account: account, predefined_disease: predefined_disease_no_group)
      service = described_class.new(disease_no_group, account)
      expect(service.group).to be_nil
    end
  end

  describe "#nudge_id" do
    it "returns a stable ID for the nudge" do
      service = described_class.new(disease, account)
      expect(service.nudge_id).to eq("join_group_#{predefined_disease.group.id}")
    end
  end

  describe "#group_nudge_eligible?" do
    context "when group exists and account is not a member" do
      it "returns true" do
        service = described_class.new(disease, account)
        expect(service.group_nudge_eligible?).to be true
      end
    end

    context "when group exists and account is already a member" do
      before do
        create(:group_member, group: predefined_disease.group, account: account)
      end

      it "returns false" do
        service = described_class.new(disease, account)
        expect(service.group_nudge_eligible?).to be false
      end
    end

    context "when group does not exist" do
      before do
        predefined_disease_no_group = create(:predefined_disease, :no_group)
        @disease_no_group = create(:disease, account: account, predefined_disease: predefined_disease_no_group)
      end

      it "returns false" do
        service = described_class.new(@disease_no_group, account)
        expect(service.group_nudge_eligible?).to be false
      end
    end

    context "when nudge has been dismissed" do
      before do
        service = described_class.new(disease, account)
        account.dismiss_nudge!(service.nudge_id)
      end

      it "returns false" do
        service = described_class.new(disease, account)
        expect(service.group_nudge_eligible?).to be false
      end
    end
  end

  describe "#eligible_nudge" do
    it "returns nudge hash when eligible" do
      service = described_class.new(disease, account)
      nudge = service.eligible_nudge

      expect(nudge).to be_a(Hash)
      expect(nudge[:id]).to eq(service.nudge_id)
      expect(nudge[:group_name]).to eq(predefined_disease.group.name)
      expect(nudge[:group_id]).to eq(predefined_disease.group.id)
    end

    it "returns nil when not eligible" do
      create(:group_member, group: predefined_disease.group, account: account)
      service = described_class.new(disease, account)
      expect(service.eligible_nudge).to be_nil
    end
  end

  describe "#dismiss!" do
    it "dismisses the nudge for the account" do
      service = described_class.new(disease, account)
      expect(account.nudge_dismissed?(service.nudge_id)).to be false

      service.dismiss!

      expect(account.nudge_dismissed?(service.nudge_id)).to be true
    end
  end
end
