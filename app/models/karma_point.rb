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
class KarmaPoint < ApplicationRecord
  REACTION_POINTS = {
    "like" => 1,
    "love" => 2,
    "sad" => 1,
    "haha" => 1,
    "angry" => -1,
    "dislike" => -1
  }.freeze

  belongs_to :account
  belongs_to :post

  validates :points, presence: true
  validates :reaction_type, presence: true, inclusion: { in: REACTION_POINTS.keys }

  after_create :increment_account_karma
  around_destroy :decrement_account_karma_around

  def self.points_for(reaction_type)
    REACTION_POINTS.fetch(reaction_type, 0)
  end

  private

  def increment_account_karma
    account.increment!(:karma_score, points)
    account.recompute_badge!
  end

  def decrement_account_karma_around
    karma_points_value = points
    account_id_value = account_id
    yield
    Account.where("karma_score >= ? AND id = ?", karma_points_value, account_id_value)
           .update_all(["karma_score = karma_score - ?", karma_points_value])
    Account.find(account_id_value)&.recompute_badge!
  end
end
