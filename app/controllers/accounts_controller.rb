class AccountsController < BaseController
  before_action :set_account, only: %i[show]
  before_action :set_breadcrumbs

  def index
    accounts_query = Account
                     .joins(user: :roles)
                     .includes(user: :roles)
                     .where(is_hidden: false)
                     .order(:username)

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      accounts_query = accounts_query.where(
        "accounts.first_name ILIKE ? OR accounts.last_name ILIKE ? OR accounts.username ILIKE ?",
        search_term, search_term, search_term
      )
    end

    @pagy, @accounts = pagy(accounts_query.all)

    @friends = current_account.friends.pluck(:id)
    @sent_friend_requests = current_account.sent_friend_requests.pluck(:friend_id)
    @received_friend_requests = current_account.received_friend_requests.pluck(:account_id)
  end

  def show
    authorize @account
    @posts = @account.posts.ordered.includes(:hashtags, :poll_options, :quoted_post, :post_bookmarks).limit(20)
  end

  private

  def set_account
    @account = Account.find(params[:id])
  end

  def set_breadcrumbs
    add_breadcrumb t("breadcrumbs.home"), authenticated_root_path
    add_breadcrumb t(".breadcrumbs.index"), accounts_path
  end
end
