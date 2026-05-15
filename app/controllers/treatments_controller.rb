class TreatmentsController < BaseController
  before_action :ensure_patient_can_create, only: %i[new create]
  before_action :set_treatment, only: %i[show edit update destroy]
  before_action :set_breadcrumbs

  def index
    @pagy, @treatments = pagy(current_account.treatments.includes(:treatment_diseases).visible.approved.all)
  end

  def show
    @pagy_treatments, @treatment_updates = pagy(@treatment.updates.order(update_date: :desc))
    @pagy_treatment_diseases, @treatment_diseases = pagy(@treatment.treatment_diseases, items: 5)
  end

  def new
    @treatment = Treatment.new
  end

  def create
    @treatment = current_account.treatments.build(treatment_params)
    @treatment.approval_status = "approved"
    @treatment.approved_by_id = current_user.id
    @treatment.approved_at = Time.current

    respond_to do |format|
      if @treatment.save
        format.html { redirect_to treatments_path, notice: t(".success") }
      else
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  def update
    respond_to do |format|
      if @treatment.update(treatment_params)
        format.html { redirect_to treatment_url(id: @treatment.id, locale: I18n.locale), notice: t(".success") }
      else
        format.html { render :edit, status: :unprocessable_content }
      end
    end
  end

  def destroy
    @treatment.destroy

    respond_to do |format|
      format.html { redirect_to treatments_path, notice: t(".success") }
    end
  end

  private

  def ensure_patient_can_create
    return unless current_user.specialist?

    redirect_to treatments_path, alert: t("treatments.create.not_allowed")
  end

  def set_treatment
    @treatment = current_account.treatments.find(params[:id])
  end

  def treatment_params
    params.expect(treatment: %i[title description start_date end_date
                                effectiveness is_finished approval_status
                                is_hidden])
  end

  def set_breadcrumbs
    add_breadcrumb t("breadcrumbs.home"), authenticated_root_path
    add_breadcrumb t(".breadcrumbs.index"), treatments_path

    case action_name.to_sym
    when :new, :create
      add_breadcrumb t(".breadcrumbs.new"), new_treatment_path
    when :show
      add_breadcrumb @treatment.title, @treatment
    when :edit, :update
      add_breadcrumb @treatment.title, @treatment
      add_breadcrumb t(".breadcrumbs.edit"), edit_treatment_path(id: @treatment.id, locale: I18n.locale)
    end
  end
end
