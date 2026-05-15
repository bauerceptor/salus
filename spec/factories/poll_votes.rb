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
FactoryBot.define do
  factory :poll_vote do
    account
    poll_option
  end
end
