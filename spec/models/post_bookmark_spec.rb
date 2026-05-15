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
require "rails_helper"

RSpec.describe PostBookmark, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:post) }
  end

  describe "validations" do
    it "validates uniqueness of account per post" do
      bookmark = create(:post_bookmark)
      expect(build(:post_bookmark, account: bookmark.account, post: bookmark.post)).not_to be_valid
    end
  end

  describe "factory" do
    it "creates a valid post bookmark" do
      bookmark = create(:post_bookmark)
      expect(bookmark).to be_valid
    end
  end

  describe "counter cache" do
    it "increments post's bookmark_count after create" do
      post = create(:post)
      expect(post.bookmark_count).to eq(0)
      create(:post_bookmark, post: post)
      expect(post.reload.bookmark_count).to eq(1)
    end

    it "decrements post's bookmark_count after destroy" do
      post = create(:post)
      bookmark = create(:post_bookmark, post: post)
      expect(post.bookmark_count).to eq(1)
      bookmark.destroy
      expect(post.reload.bookmark_count).to eq(0)
    end
  end
end
