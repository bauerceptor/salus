# == Schema Information
#
# Table name: poll_votes
#
#  id            :uuid             not null, primary key
#  account_id    :uuid             not null
#  poll_option_id :uuid             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_poll_votes_on_account_id     (account_id)
#  index_poll_votes_on_poll_option_id (poll_option_id)
#  index_poll_votes_unique            (account_id, poll_option_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (poll_option_id => poll_options.id)
#
class PollVote < ApplicationRecord
  belongs_to :account
  belongs_to :poll_option

  validates :account_id, uniqueness: { scope: :poll_option_id }

  after_create :increment_option_vote_count
  around_destroy :decrement_option_vote_count_around

  private

  def increment_option_vote_count
    poll_option&.increment_vote_count
  end

  def decrement_option_vote_count_around
    option_id = poll_option_id
    vote_count_before = PollOption.where(id: option_id).pick(:vote_count)
    yield
    return unless option_id && vote_count_before&.positive?

    PollOption.where("vote_count > 0 AND id = ?", option_id)
              .update_all("vote_count = vote_count - 1")
  end
end
