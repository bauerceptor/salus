# == Schema Information
#
# Table name: comments
#
#  id               :uuid             not null, primary key
#  body             :text             default(""), not null
#  commentable_type :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :uuid             not null
#  commentable_id   :uuid             not null
#  expert_pinned_at :datetime
#
# Indexes
#
#  index_comments_on_account_id   (account_id)
#  index_comments_on_commentable  (commentable_type,commentable_id)
#  index_comments_on_expert_pinned_at (expert_pinned_at)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
require "rails_helper"

RSpec.describe Comment, type: :model do
  describe "factory" do
    it "has a valid factory" do
      expect(build(:comment)).to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:commentable) }
    it { is_expected.to belong_to(:account) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_most(500) }
  end

  describe "#expert_pinned?" do
    it "returns false for unpinned comment" do
      comment = build(:comment, expert_pinned_at: nil)
      expect(comment.expert_pinned?).to be false
    end

    it "returns true for pinned comment" do
      comment = build(:comment, expert_pinned_at: Time.current)
      expect(comment.expert_pinned?).to be true
    end
  end

  describe "#pin_as_expert!" do
    let(:post) { create(:post) }
    let(:specialist_user) { create(:user, :specialist) }
    let(:patient_account) { create(:account) }

    before do
      create(:specialist_patient, specialist: specialist_user, account: patient_account, status: "active")
    end

    it "returns false for non-specialist" do
      regular_user = create(:user)
      comment = create(:comment, account: regular_user.account, commentable: post)
      result = comment.pin_as_expert!(regular_user.account)
      expect(result).to be false
      expect(comment.expert_pinned?).to be false
    end

    it "returns false for specialist without patients" do
      other_specialist = create(:user, :specialist)
      comment = create(:comment, account: other_specialist.account, commentable: post)
      result = comment.pin_as_expert!(other_specialist.account)
      expect(result).to be false
    end

    it "pins comment for specialist with patients" do
      comment = create(:comment, account: specialist_user.account, commentable: post)
      result = comment.pin_as_expert!(specialist_user.account)
      expect(result).to be true
      expect(comment.reload.expert_pinned?).to be true
    end
  end

  describe "#unpin_as_expert!" do
    it "clears expert_pinned_at" do
      comment = build(:comment, expert_pinned_at: Time.current)
      comment.unpin_as_expert!
      expect(comment.expert_pinned?).to be false
    end
  end

  describe "scopes" do
    describe ".expert_pinned" do
      it "returns only expert pinned comments" do
        post = create(:post)
        pinned = create(:comment, commentable: post, expert_pinned_at: Time.current)
        unpinned = create(:comment, commentable: post)
        expect(described_class.expert_pinned).to include(pinned)
        expect(described_class.expert_pinned).not_to include(unpinned)
      end
    end
  end
end
