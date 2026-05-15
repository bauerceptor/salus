# == Schema Information
#
# Table name: hashtags
#
#  id            :uuid             not null, primary key
#  name          :string           not null
#  post_count    :integer          default: 0
#  trending_score :integer          default: 0
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_hashtags_on_name          (name) UNIQUE
#  index_hashtags_on_trending_score (trending_score)
#
require "rails_helper"

RSpec.describe Hashtag, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:post_hashtags).dependent(:destroy) }
    it { is_expected.to have_many(:posts).through(:post_hashtags) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it "validates uniqueness of name case-insensitively" do
      create(:hashtag, name: "Ruby")
      expect(build(:hashtag, name: "ruby")).not_to be_valid
    end
  end

  describe "factory" do
    it "creates a valid hashtag" do
      hashtag = create(:hashtag)
      expect(hashtag).to be_valid
      expect(hashtag.name).to be_present
    end
  end

  describe "#extract_from_content" do
    it "extracts hashtags from content" do
      content = "Hello #world this is #rails"
      hashtags = described_class.extract_from_content(content)
      expect(hashtags).to match_array(%w[world rails])
    end

    it "normalizes hashtag names to lowercase" do
      content = "Check out #RubyOnRails"
      hashtags = described_class.extract_from_content(content)
      expect(hashtags).to include("rubyonrails")
    end

    it "handles content with no hashtags" do
      content = "Hello world without any tags"
      hashtags = described_class.extract_from_content(content)
      expect(hashtags).to be_empty
    end

    it "does not extract numbers-only hashtags" do
      content = "Testing #123 invalid"
      hashtags = described_class.extract_from_content(content)
      expect(hashtags).not_to include("123")
    end
  end

  describe "#increment_post_count" do
    it "increments the post count" do
      hashtag = create(:hashtag, post_count: 0)
      hashtag.increment_post_count
      expect(hashtag.post_count).to eq(1)
    end
  end

  describe "#decrement_post_count" do
    it "decrements the post count" do
      hashtag = create(:hashtag, post_count: 5)
      hashtag.decrement_post_count
      expect(hashtag.post_count).to eq(4)
    end

    it "does not go below zero" do
      hashtag = create(:hashtag, post_count: 0)
      hashtag.decrement_post_count
      expect(hashtag.post_count).to eq(0)
    end
  end
end
