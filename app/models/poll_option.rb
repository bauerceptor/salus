# == Schema Information
#
# Table name: poll_options
#
#  id         :uuid             not null, primary key
#  post_id    :uuid             not null
#  option_text :string           not null
#  vote_count :integer          default: 0
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_poll_options_on_post_id (post_id)
#
# Foreign Keys
#
#  fk_rails_...  (post_id => posts.id)
#
class PollOption < ApplicationRecord
  belongs_to :post
  has_many :poll_votes, dependent: :destroy

  validates :option_text, presence: true, length: { maximum: 200 }

  after_destroy :decrement_post_votes_count

  def increment_vote_count
    increment!(:vote_count)
  end

  def decrement_vote_count
    return if vote_count <= 0

    decrement!(:vote_count)
  end

  private

  def decrement_post_votes_count
    post&.decrement!(:poll_votes_count)
  end
end
