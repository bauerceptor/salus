class MedicationsController < BaseController
  before_action :set_medication, only: %i[show edit update destroy]
  before_action :set_breadcrumbs

  def index
    @pagy, @medications = pagy(current_account.medications.active.includes(:disease, :medication_schedules).all)
  end

  def show
    @pagy_schedules, @medication_schedules = pagy(@medication.medication_schedules.active.order(:scheduled_time),
                                                  items: 10)
    @pagy_logs, @medication_logs = pagy(@medication.medication_logs.order(scheduled_for: :desc).limit(50))
  end

  def new
    @medication = Medication.new
    @diseases = current_account.diseases.includes(:predefined_disease)
  end

  def edit
    @diseases = current_account.diseases.includes(:predefined_disease)
  end

  def create
    @medication = current_account.medications.build(medication_params)

    respond_to do |format|
      if @medication.save
        format.html { redirect_to medications_path, notice: t(".success") }
      else
        @diseases = current_account.diseases.includes(:predefined_disease)
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  def update
    authorize @medication

    respond_to do |format|
      if @medication.update(medication_params)
        format.html { redirect_to medication_url(id: @medication.id, locale: I18n.locale), notice: t(".success") }
      else
        @diseases = current_account.diseases.includes(:predefined_disease)
        format.html { render :edit, status: :unprocessable_content }
      end
    end
  end

  def destroy
    authorize @medication
    @medication.destroy

    respond_to do |format|
      format.html { redirect_to medications_path, notice: t(".success") }
    end
  end

  private

  def set_medication
    @medication = current_account.medications.find(params[:id])
  end

  def medication_params
    params.expect(medication: %i[name dosage frequency instructions
                                 start_date end_date is_active notes
                                 disease_id reminder_enabled reminder_minutes_before])
  end

  def set_breadcrumbs
    add_breadcrumb t("breadcrumbs.home"), authenticated_root_path
    add_breadcrumb t(".breadcrumbs.index"), medications_path

    case action_name.to_sym
    when :new, :create
      add_breadcrumb t(".breadcrumbs.new"), new_medication_path
    when :show
      add_breadcrumb @medication.name, @medication
    when :edit, :update
      add_breadcrumb @medication.name, @medication
      add_breadcrumb t(".breadcrumbs.edit"), edit_medication_path(id: @medication.id, locale: I18n.locale)
    end
  end
end
