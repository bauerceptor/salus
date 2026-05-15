# == Schema Information
#
# Table name: post_bookmarks
#
#  id         :uuid             not null, primary key
#  account_id :uuid             not null
#  post_id    :uuid             not null
#  created_at :datetime          not null
#  updated_at :datetime          not null
#
# Indexes
#
#  index_post_bookmarks_on_account_id (account_id)
#  index_post_bookmarks_on_post_id    (post_id)
#  index_post_bookmarks_unique        (account_id, post_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (post_id => posts.id)
#
class PostBookmark < ApplicationRecord
  belongs_to :account
  belongs_to :post

  validates :account_id, uniqueness: { scope: :post_id }

  after_create :increment_post_bookmark_count
  after_destroy :decrement_post_bookmark_count

  private

  def increment_post_bookmark_count
    post&.increment!(:bookmark_count)
  end

  def decrement_post_bookmark_count
    post.decrement!(:bookmark_count) if post&.bookmark_count&.positive?
  end
end
