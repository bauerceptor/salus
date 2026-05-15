# == Schema Information
#
# Table name: post_hashtags
#
#  id         :uuid             not null, primary key
#  post_id    :uuid             not null
#  hashtag_id :uuid             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_post_hashtags_on_post_id_and_hashtag_id  (post_id, hashtag_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (hashtag_id => hashtags.id)
#  fk_rails_...  (post_id => posts.id)
#
class PostHashtag < ApplicationRecord
  belongs_to :post
  belongs_to :hashtag

  validates :post_id, uniqueness: { scope: :hashtag_id }
end
