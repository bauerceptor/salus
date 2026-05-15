class Groups::PostsController < Groups::BaseController
  before_action :set_breadcrumbs

  def index
    set_posts
    set_liked_posts
  end

  def new
    @post = Post.new
  end

  def create
    @post = @group.posts.build(post_params)
    @post.account = current_account

    if @post.save
      set_posts
      set_liked_posts
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to group_posts_path(group_id: @group.id), notice: t(".success") }
      end
    else
      set_posts
      set_liked_posts
      respond_to do |format|
        format.turbo_stream
        format.html { render :index, status: :unprocessable_content }
      end
    end
  end

  private

  def set_posts
    @pagy, @posts = pagy(@group.posts.order(created_at: :desc))
  end

  def set_liked_posts
    @liked_posts = Reaction.where(
      account: current_account,
      reaction_type: "like",
      reactable_type: "Post"
    ).pluck(:reactable_id)
  end

  def post_params
    params.expect(post: %i[body post_type metadata])
  end

  def set_breadcrumbs
    add_breadcrumb t("groups.posts_controller.breadcrumbs.index"), group_posts_path(group_id: @group.id)
  end
end
