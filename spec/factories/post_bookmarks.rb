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
FactoryBot.define do
  factory :post_bookmark do
    account
    post
  end
end
