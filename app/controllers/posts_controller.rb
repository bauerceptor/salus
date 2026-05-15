class PostsController < BaseController
  before_action :set_account
  before_action :set_referrer, only: %i[new create]

  def index
    @pagy, @posts = pagy(
      DiseaseStatus
      .joins(:disease)
      .where(disease: { account_id: @account.id })
      .visible
      .includes(:disease, :comments, :reactions, disease: %i[predefined_disease account])
      .order(created_at: :desc),
      items: 10
    )

    @liked_statuses = Reaction.where(
      account: current_account,
      reaction_type: "like",
      reactable_type: "DiseaseStatus"
    ).pluck(:reactable_id)
  end

  def new
    @post = DiseaseStatus.new
    setup_new_form_vars
  end

  def create
    @disease = current_account.diseases.find_by(id: params[:disease_status][:disease_id])

    if @disease.blank?
      setup_new_form_vars
      @post = DiseaseStatus.new
      @post.errors.add(:disease_id, I18n.t("errors.messages.blank"))
      return render :new, status: :unprocessable_content
    end

    @post = @disease.statuses.build(post_params)

    if @post.save
      respond_to do |format|
        format.html { redirect_to redirect_url, notice: "Post created successfully." }
        format.turbo_stream { redirect_to redirect_url }
      end
    else
      setup_new_form_vars
      render :new, status: :unprocessable_content
    end
  end

  private

  def post_params
    params.expect(disease_status: %i[content status]).tap do |p|
      p[:status] = "diagnosed" if p[:status].blank?
    end
  end

  def setup_new_form_vars
    @diseases = current_account.diseases.all
    @status_options = DiseaseStatus::STATUSES.map do |key|
      [I18n.t("activerecord.attributes.disease_status.statuses.#{key}"), key]
    end
  end

  def set_account
    @account = Account.find(params[:account_id])
  end

  def set_referrer
    @referrer = request.headers["Referer"]
  end

  def redirect_url
    @referrer.presence || authenticated_root_path
  end
end
