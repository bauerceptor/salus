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
require "rails_helper"

RSpec.describe PollVote, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:poll_option) }
  end

  describe "validations" do
    it "validates uniqueness of account per poll option" do
      vote = create(:poll_vote)
      expect(build(:poll_vote, account: vote.account, poll_option: vote.poll_option)).not_to be_valid
    end
  end

  describe "factory" do
    it "creates a valid poll vote" do
      vote = create(:poll_vote)
      expect(vote).to be_valid
    end
  end

  describe "after_create callback" do
    it "increments the poll option vote count" do
      option = create(:poll_option, vote_count: 0)
      create(:poll_vote, poll_option: option)
      expect(option.reload.vote_count).to eq(1)
    end
  end
end
