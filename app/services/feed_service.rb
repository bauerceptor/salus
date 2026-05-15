class FeedService
  def initialize(account)
    @account = account
  end

  def feed(page: 1, per_page: 20)
    posts = fetch_posts
    statuses = fetch_statuses

    feed_items = merge_and_sort(posts, statuses)

    @pagy, paginated_items = pagy_array(feed_items, page: page, page_size: per_page)
    [@pagy, paginated_items]
  end

  private

  def fetch_posts
    group_ids = @account.groups.pluck(:id)
    Post.feed
        .where(group_id: group_ids)
        .includes(:account, :hashtags, :poll_options, :quoted_post)
        .to_a
  end

  def fetch_statuses
    friend_ids = @account.friends.pluck(:id)
    DiseaseStatus.visible
                 .where(disease: { account_id: friend_ids })
                 .includes(:disease)
                 .to_a
  end

  def merge_and_sort(posts, statuses)
    feed_items = posts.map { |post| FeedItem.new(:post, post) } +
                 statuses.map { |status| FeedItem.new(:disease_status, status) }
    feed_items.sort_by(&:created_at).reverse
  end

  def pagy_array(items, page:, page_size: 20)
    pagy = Pagy.new(count: items.size, page: page, items: page_size)
    [pagy, items[(pagy.offset)..(pagy.offset + page_size - 1)]]
  end
end

class FeedItem
  attr_reader :type, :item

  def initialize(type, item)
    @type = type
    @item = item
  end

  delegate :created_at, to: :item

  def account
    case type
    when :post then item.account
    when :disease_status then item.disease.account
    end
  end
end
