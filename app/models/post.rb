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
class Post < ApplicationRecord
  belongs_to :account
  belongs_to :group
  belongs_to :quoted_post, class_name: "Post", optional: true

  has_many :comments, as: :commentable, dependent: :destroy
  has_many :reactions, as: :reactable, dependent: :destroy
  has_many :post_hashtags, dependent: :destroy
  has_many :hashtags, through: :post_hashtags
  has_many :poll_options, dependent: :destroy
  has_many :quotes, class_name: "Post", foreign_key: "quoted_post_id", dependent: :nullify
  has_many :post_bookmarks, dependent: :destroy
  has_many :karma_points, dependent: :destroy

  enum :post_type, { text: 0, link: 1, image: 2, poll: 3, quote: 4 }, prefix: :post_type

  validates :body, presence: true, length: { maximum: 500 }
  validates :post_type, presence: true

  after_validation :generate_link_preview, if: :link_post?
  around_destroy :decrement_hashtag_counts_around
  around_destroy :decrement_quoted_post_quote_count, if: :quote_post?
  after_save :extract_and_link_hashtags
  after_save :increment_quoted_post_quote_count, if: :quote_post?

  scope :ordered, -> { order(created_at: :desc) }
  scope :pinned, -> { where.not(pinned_at: nil).order(pinned_at: :desc) }
  scope :feed, lambda {
    order(Arel.sql("CASE WHEN pinned_at IS NULL THEN 1 ELSE 0 END"), pinned_at: :desc, created_at: :desc)
  }

  def pinned?
    pinned_at.present?
  end

  def pin!
    return false unless pinned_at.nil?

    Post.where(group_id: group_id).where.not(pinned_at: nil).update_all(pinned_at: nil)
    update!(pinned_at: Time.current)
  end

  def unpin!
    update!(pinned_at: nil) if pinned_at.present?
  end

  def link_url
    metadata["link_url"]
  end

  def link_url=(value)
    self.metadata ||= {}
    metadata["link_url"] = value
  end

  def link_preview
    metadata["link_preview"]
  end

  def extracted_hashtags
    Hashtag.extract_from_content(body)
  end

  def quote_post?
    quoted_post_id.present?
  end

  private

  def link_post?
    post_type == "link" && link_url.present?
  end

  def generate_link_preview
    return unless link_post?

    preview = LinkPreviewService.new(link_url).call
    return unless preview

    self.metadata ||= {}
    metadata["link_preview"] = preview
  end

  def extract_and_link_hashtags
    return if destroyed?

    hashtag_names = Hashtag.extract_from_content(body)
    hashtag_names.each do |name|
      hashtag = Hashtag.find_or_create_by!(name: name)
      PostHashtag.find_or_create_by!(post: self, hashtag: hashtag)
      hashtag.increment_post_count
    end
  end

  def decrement_hashtag_counts_around
    hashtag_ids = PostHashtag.where(post_id: id).pluck(:hashtag_id)
    PostHashtag.where(post_id: id).delete_all
    unless hashtag_ids.empty?
      Hashtag.where("post_count > 0 AND id IN (?)", hashtag_ids)
             .update_all("post_count = post_count - 1")
    end
    yield
  end

  def increment_quoted_post_quote_count
    return unless quote_post?

    Post.where(id: quoted_post_id).update_all("quote_count = quote_count + 1")
  end

  def decrement_quoted_post_quote_count
    return unless quote_post?

    quoted_id = quoted_post_id
    yield
    Post.where("quote_count > 0 AND id = ?", quoted_id)
        .update_all("quote_count = quote_count - 1")
  end
end
