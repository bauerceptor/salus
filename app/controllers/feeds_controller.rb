class FeedsController < BaseController
  before_action :set_breadcrumbs

  def show
    @pagy, @feed_items = FeedService.new(current_account).feed(page: params[:page])
  end

  private

  def set_breadcrumbs
    add_breadcrumb t("breadcrumbs.home"), authenticated_root_path
    add_breadcrumb t(".breadcrumbs.feed"), feed_path
  end
end
