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
require "rails_helper"

RSpec.describe PollOption, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:post) }
    it { is_expected.to have_many(:poll_votes).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:option_text) }
    it { is_expected.to validate_length_of(:option_text).is_at_most(200) }
  end

  describe "factory" do
    it "creates a valid poll option" do
      option = create(:poll_option)
      expect(option).to be_valid
      expect(option.option_text).to be_present
    end
  end

  describe "#increment_vote_count" do
    it "increments the vote count" do
      option = create(:poll_option, vote_count: 0)
      option.increment_vote_count
      expect(option.vote_count).to eq(1)
    end
  end

  describe "#decrement_vote_count" do
    it "decrements the vote count" do
      option = create(:poll_option, vote_count: 5)
      option.decrement_vote_count
      expect(option.vote_count).to eq(4)
    end

    it "does not go below zero" do
      option = create(:poll_option, vote_count: 0)
      option.decrement_vote_count
      expect(option.vote_count).to eq(0)
    end
  end
end
