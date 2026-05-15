require "rails_helper"

RSpec.describe SharedAccess, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:shared_with_account).class_name("Account") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:shared_with_account_id) }
  end

  describe "scopes" do
    let(:owner) { create(:account) }
    let(:recipient) { create(:account) }

    describe ".for_shared_with" do
      it "returns shared accesses for a specific recipient" do
        access = create(:shared_access, account: owner, shared_with_account: recipient)
        other_access = create(:shared_access, shared_with_account: recipient)
        expect(described_class.for_shared_with(recipient)).to include(access)
        expect(described_class.for_shared_with(recipient)).to include(other_access)
      end
    end

    describe ".for_shareable" do
      it "returns accesses for a specific shareable resource" do
        disease = create(:disease, account: owner)
        access = create(:shared_access, account: owner, shared_with_account: recipient, shareable: disease)
        other_access = create(:shared_access, account: owner, shared_with_account: recipient)
        expect(described_class.for_shareable(disease.class.name, disease.id)).to include(access)
        expect(described_class.for_shareable(disease.class.name, disease.id)).not_to include(other_access)
      end
    end
  end
end
