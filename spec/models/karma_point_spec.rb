# == Schema Information
#
# Table name: karma_points
#
#  id         :uuid             not null, primary key
#  account_id :uuid             not null
#  post_id    :uuid             not null
#  reaction_type :string         not null
#  points     :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_karma_points_on_account_id (account_id)
#  index_karma_points_on_post_id    (post_id)
#  index_karma_points_on_account_id_and_post_id (account_id, post_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (post_id => posts.id)
#
require "rails_helper"

RSpec.describe KarmaPoint, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:post) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:points) }
    it { is_expected.to validate_presence_of(:reaction_type) }
    it { is_expected.to validate_inclusion_of(:reaction_type).in_array(%w[like love sad haha angry dislike]) }
  end

  describe "factory" do
    it "creates a valid karma point" do
      karma = create(:karma_point)
      expect(karma).to be_valid
    end
  end

  describe ".points_for" do
    it "returns correct points for like" do
      expect(described_class.points_for("like")).to eq(1)
    end

    it "returns correct points for love" do
      expect(described_class.points_for("love")).to eq(2)
    end

    it "returns correct points for sad" do
      expect(described_class.points_for("sad")).to eq(1)
    end

    it "returns correct points for haha" do
      expect(described_class.points_for("haha")).to eq(1)
    end

    it "returns correct points for angry" do
      expect(described_class.points_for("angry")).to eq(-1)
    end

    it "returns correct points for dislike" do
      expect(described_class.points_for("dislike")).to eq(-1)
    end

    it "returns 0 for unknown reaction type" do
      expect(described_class.points_for("unknown")).to eq(0)
    end
  end

  describe "counter cache" do
    it "increments account karma_score after create" do
      account = create(:account, karma_score: 0)
      post = create(:post)
      create(:karma_point, account: account, post: post, points: 2)
      expect(account.reload.karma_score).to eq(2)
    end

    it "decrements account karma_score after destroy" do
      account = create(:account, karma_score: 5)
      post = create(:post)
      karma = create(:karma_point, account: account, post: post, points: 3)
      expect(account.reload.karma_score).to eq(8)
      karma.destroy
      expect(account.reload.karma_score).to eq(5)
    end
  end
end
