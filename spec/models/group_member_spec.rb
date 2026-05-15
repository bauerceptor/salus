require "rails_helper"

RSpec.describe GroupMember, type: :model do
  describe "enums" do
    it { is_expected.to define_enum_for(:role).with_values(member: 0, moderator: 1, admin: 2).with_prefix(:role) }
  end

  describe "factory" do
    it "creates a valid group member" do
      membership = create(:group_member)
      expect(membership).to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:account) }
  end

  describe "validations" do
    it "validates uniqueness of account per group" do
      membership = create(:group_member)
      expect(build(:group_member, account: membership.account, group: membership.group)).not_to be_valid
    end
  end

  describe "after_create callback" do
    it "sets first member as admin" do
      group = create(:group)
      account = create(:account)
      membership = create(:group_member, group: group, account: account)
      expect(membership.reload.role).to eq("admin")
    end

    it "sets second member as member" do
      group = create(:group)
      account1 = create(:account)
      account2 = create(:account)
      create(:group_member, group: group, account: account1)
      membership = create(:group_member, group: group, account: account2)
      expect(membership.reload.role).to eq("member")
    end
  end

  describe "#specialist?" do
    let!(:group) { create(:group) }
    let!(:patient_account) { create(:account) }
    let!(:disease) { create(:disease, account: patient_account) }

    before do
      group.predefined_disease_id = disease.predefined_disease_id
      group.save!
    end

    it "returns false for non-specialist" do
      membership = create(:group_member, group: group, account: patient_account)
      expect(membership.specialist?).to be false
    end

    it "returns false for specialist without patients with that disease" do
      specialist_user = create(:user, :specialist)
      specialist_account = specialist_user.account
      membership = create(:group_member, group: group, account: specialist_account)
      expect(membership.specialist?).to be false
    end

    it "returns true for specialist with patients in that disease group" do
      specialist_user = create(:user, :specialist)
      create(:specialist_patient, specialist: specialist_user, account: patient_account, status: "active")
      membership = create(:group_member, group: group, account: specialist_user.account)
      expect(membership.specialist?).to be true
    end
  end
end
