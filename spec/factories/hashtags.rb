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
FactoryBot.define do
  factory :hashtag do
    sequence(:name) { |n| "hashtag#{n}" }
    post_count { 0 }
    trending_score { 0 }
  end
end
