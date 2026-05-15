# == Schema Information
#
# Table name: posts
#
#  id            :uuid             not null, primary key
#  body          :string           default(""), not null
#  post_type     :integer          default: 0, not null
#  metadata      :jsonb            default: {}
#  account_id    :uuid             not null
#  group_id      :uuid             not null
#  quoted_post_id :uuid
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_posts_on_account_id     (account_id)
#  index_posts_on_group_id       (group_id)
#  index_posts_on_post_type      (post_type)
#  index_posts_on_quoted_post_id (quoted_post_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (group_id => groups.id)
#  fk_rails_...  (quoted_post_id => posts.id)
#
require "rails_helper"

RSpec.describe Post, type: :model do
  describe "enums" do
    it {
      is_expected.to define_enum_for(:post_type).with_values(text: 0, link: 1, image: 2, poll: 3,
                                                             quote: 4).with_prefix(:post_type)
    }
  end

  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_many(:reactions).dependent(:destroy) }
    it { is_expected.to belong_to(:quoted_post).class_name("Post").optional }
  end

  describe "validations" do
    describe "body" do
      it { is_expected.to validate_presence_of(:body) }
      it { is_expected.to validate_length_of(:body).is_at_most(500) }
    end

    describe "post_type" do
      it { is_expected.to validate_presence_of(:post_type) }
    end
  end

  describe "factory" do
    it "creates a valid text post" do
      post = create(:post)
      expect(post).to be_valid
      expect(post.post_type_text?).to be true
      expect(post.body).to be_present
    end

    it "creates a link post with metadata" do
      post = create(:post, :link, metadata: { link_url: "https://example.com/article" })
      expect(post.post_type_link?).to be true
      expect(post.metadata["link_url"]).to eq("https://example.com/article")
    end

    it "creates an image post with metadata" do
      post = create(:post, :image, metadata: { image_data: "shrine_data" })
      expect(post.post_type_image?).to be true
      expect(post.metadata["image_data"]).to eq("shrine_data")
    end
  end

  describe "scopes" do
    let!(:group) { create(:group) }
    let!(:account) { create(:account) }

    it "orders by created_at desc by default" do
      create(:post, group: group, account: account, created_at: 1.day.ago)
      newer = create(:post, group: group, account: account, created_at: Time.current)
      expect(described_class.ordered.first).to eq(newer)
    end
  end

  describe "link preview generation" do
    let!(:group) { create(:group) }
    let!(:account) { create(:account) }

    it "generates link preview for link posts on save" do
      link_preview = { "title" => "Example", "description" => "Description", "image" => "http://example.com/img.jpg" }
      allow(LinkPreviewService).to receive(:new).with("https://example.com").and_return(
        instance_double(LinkPreviewService, call: link_preview)
      )

      post = create(:post, :link, group: group, account: account, metadata: { "link_url" => "https://example.com" })

      expect(post.link_preview).to eq(link_preview)
    end

    it "does not generate preview for text posts" do
      post = create(:post, group: group, account: account)
      expect(LinkPreviewService).not_to receive(:new)
      expect(post.link_preview).to be_nil
    end

    it "returns nil for link_post without link_url" do
      post = build(:post, :link, group: group, account: account, metadata: {})
      post.valid?
      expect(post.link_preview).to be_nil
    end
  end

  describe "#link_url" do
    it "gets link_url from metadata" do
      post = build(:post, metadata: { "link_url" => "https://example.com" })
      expect(post.link_url).to eq("https://example.com")
    end

    it "sets link_url in metadata" do
      post = build(:post)
      post.link_url = "https://example.com"
      expect(post.metadata["link_url"]).to eq("https://example.com")
    end
  end

  describe "hashtag extraction" do
    let!(:group) { create(:group) }
    let!(:account) { create(:account) }

    it "extracts hashtags from body after save" do
      post = create(:post, group: group, account: account, body: "Hello #world #rails")
      post.reload
      expect(post.hashtags.pluck(:name)).to match_array(%w[world rails])
    end

    it "increments hashtag post_count after save" do
      post = create(:post, group: group, account: account, body: "Check #health")
      hashtag = post.hashtags.first
      expect(hashtag.post_count).to eq(1)
    end

    it "does not create duplicate post_hashtags" do
      create(:post, group: group, account: account, body: "Hello #world")
      post2 = create(:post, group: group, account: account, body: "World #world")
      expect(post2.hashtags.where(name: "world").count).to eq(1)
    end
  end

  describe "poll associations" do
    let!(:group) { create(:group) }
    let!(:account) { create(:account) }

    it "has many poll_options for poll posts" do
      poll_post = create(:post, :poll, group: group, account: account)
      option1 = create(:poll_option, post: poll_post)
      option2 = create(:poll_option, post: poll_post)
      expect(poll_post.poll_options).to contain_exactly(option1, option2)
    end

    it "can create poll options after poll post creation" do
      poll_post = create(:post, :poll, group: group, account: account)
      poll_post.poll_options.create!(option_text: "Yes")
      poll_post.poll_options.create!(option_text: "No")
      expect(poll_post.poll_options.count).to eq(2)
    end
  end

  describe "quote associations" do
    let!(:group) { create(:group) }
    let!(:account) { create(:account) }

    it "belongs to a quoted post" do
      original = create(:post, group: group, account: account)
      quote_post = create(:post, :quote, group: group, account: account, quoted_post: original)
      expect(quote_post.quoted_post).to eq(original)
    end

    it "has many quotes" do
      original = create(:post, group: group, account: account)
      quote1 = create(:post, :quote, group: group, account: account, quoted_post: original)
      quote2 = create(:post, :quote, group: group, account: account, quoted_post: original)
      expect(original.quotes).to contain_exactly(quote1, quote2)
    end

    it "increments quote_count on quoted post after save" do
      original = create(:post, group: group, account: account)
      expect(original.quote_count).to eq(0)
      create(:post, :quote, group: group, account: account, quoted_post: original)
      expect(original.reload.quote_count).to eq(1)
    end

    it "#quote_post? returns true for quote posts with quoted_post_id" do
      original = create(:post, group: group, account: account)
      quote_post = create(:post, :quote, group: group, account: account, quoted_post: original)
      expect(quote_post.quote_post?).to be true
    end

    it "#quote_post? returns false for non-quote posts" do
      text_post = create(:post, group: group, account: account)
      expect(text_post.quote_post?).to be false
    end
  end

  describe "bookmark associations" do
    let!(:group) { create(:group) }
    let!(:account) { create(:account) }

    it "has many post_bookmarks" do
      post = create(:post, group: group, account: account)
      bookmark1 = create(:post_bookmark, post: post, account: account)
      bookmark2 = create(:post_bookmark, post: post, account: create(:account))
      expect(post.post_bookmarks).to contain_exactly(bookmark1, bookmark2)
    end

    it "increments bookmark_count when bookmarked" do
      post = create(:post, group: group, account: account)
      create(:post_bookmark, post: post, account: account)
      expect(post.reload.bookmark_count).to eq(1)
    end

    it "decrements bookmark_count when bookmark removed" do
      post = create(:post, group: group, account: account)
      bookmark = create(:post_bookmark, post: post, account: account)
      expect(post.reload.bookmark_count).to eq(1)
      bookmark.destroy
      expect(post.reload.bookmark_count).to eq(0)
    end
  end

  describe "pin functionality" do
    let!(:group) { create(:group) }
    let!(:account) { create(:account) }

    it "#pinned? returns false for unpinned post" do
      post = create(:post, group: group, account: account)
      expect(post.pinned?).to be false
    end

    it "#pin! pins a post" do
      post = create(:post, group: group, account: account)
      post.pin!
      expect(post.reload.pinned?).to be true
    end

    it "#unpin! unpins a post" do
      post = create(:post, group: group, account: account)
      post.pin!
      post.unpin!
      expect(post.reload.pinned?).to be false
    end

    it "#pin! only allows one pinned post per group" do
      post1 = create(:post, group: group, account: account)
      post2 = create(:post, group: group, account: account)
      post1.pin!
      post2.pin!
      expect(post1.reload.pinned?).to be false
      expect(post2.reload.pinned?).to be true
    end

    describe "scopes" do
      it ".pinned returns only pinned posts" do
        post1 = create(:post, group: group, account: account)
        post2 = create(:post, group: group, account: account)
        post1.pin!
        expect(described_class.pinned).to include(post1)
        expect(described_class.pinned).not_to include(post2)
      end

      it ".feed orders pinned first then by created_at" do
        older = create(:post, group: group, account: account, created_at: 1.day.ago)
        newer = create(:post, group: group, account: account)
        newer.pin!
        feed = described_class.feed.to_a
        expect(feed.first).to eq(newer)
        expect(feed.second).to eq(older)
      end
    end
  end
end
