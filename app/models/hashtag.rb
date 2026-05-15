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
class Hashtag < ApplicationRecord
  has_many :post_hashtags, dependent: :destroy
  has_many :posts, through: :post_hashtags

  validates :name, presence: true, uniqueness: true

  before_validation :normalize_name

  def self.extract_from_content(content)
    content.scan(/#([a-zA-Z][a-zA-Z0-9_]*)/).flatten.map(&:downcase)
  end

  def increment_post_count
    increment!(:post_count)
  end

  def decrement_post_count
    decrement!(:post_count) if post_count.positive?
  end

  private

  def normalize_name
    self.name = name.downcase if name.present?
  end
end
