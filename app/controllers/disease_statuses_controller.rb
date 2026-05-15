class DiseaseStatusesController < BaseController
  include DiseaseSettable

  before_action :set_disease_status, only: %i[show edit update destroy]
  before_action :set_disease_status_options, only: %i[new create edit update]
  before_action :set_breadcrumbs

  def index
    @pagy, @disease_statuses = pagy(
      @disease
      .statuses
      .order(created_at: :desc)
      .includes(:comments, :reactions),
      items: 8
    )

    @liked_statuses = Reaction.where(
      account: current_account,
      reaction_type: "like",
      reactable_type: "DiseaseStatus"
    ).pluck(:reactable_id)
  end

  def new
    @disease_status = DiseaseStatus.new
    @url = disease_statuses_path
  end

  def edit
    @url = disease_statuses_path
  end

  def create
    @disease_status = @disease.statuses.build(disease_status_params)

    respond_to do |format|
      if @disease_status.save
        format.html { redirect_to disease_statuses_path, notice: t(".success") }
      else
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  def update
    authorize @disease_status

    respond_to do |format|
      if @disease_status.update(disease_status_params)
        format.html do
          redirect_to disease_status_path(disease_id: @disease.id, id: @disease_status.id, locale: I18n.locale),
                      notice: t(".success")
        end
      else
        format.html { render :edit, status: :unprocessable_content }
      end
    end
  end

  def destroy
    authorize @disease_status
    @disease_status.destroy

    respond_to do |format|
      format.html { redirect_to disease_statuses_path, notice: t(".success") }
    end
  end

  private

  def set_disease_status
    @disease_status = @disease.statuses.find(params[:id])
  end

  def set_disease_status_options
    @disease_status_options = DiseaseStatus::STATUSES.map do |key|
      [I18n.t("activerecord.attributes.disease_status.statuses.#{key}"), key]
    end
  end

  def disease_status_params
    params.expect(disease_status: %i[content mood status hidden])
  end

  def set_breadcrumbs
    add_breadcrumb t("diseases.breadcrumbs.home"), authenticated_root_path
    add_breadcrumb t("diseases.breadcrumbs.index"), diseases_path
    add_breadcrumb @disease.predefined_disease.name, disease_path(id: @disease.id, locale: I18n.locale)
    add_breadcrumb t(".breadcrumbs.index"), disease_statuses_path(disease_id: @disease.id, locale: I18n.locale)

    case action_name.to_sym
    when :new, :create
      add_breadcrumb t(".breadcrumbs.new"), new_disease_status_path(disease_id: @disease.id, locale: I18n.locale)
    when :show
      add_breadcrumb t(".breadcrumbs.show", date: @disease_status.updated_at),
                     disease_status_path(disease_id: @disease.id, id: @disease_status.id, locale: I18n.locale)
    when :edit, :update
      add_breadcrumb t(".breadcrumbs.edit"),
                     edit_disease_status_path(disease_id: @disease.id, id: @disease_status.id, locale: I18n.locale)
    end
  end
end
