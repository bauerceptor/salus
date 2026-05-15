class Medications::MedicationSchedulesController < BaseController
  before_action :set_medication

  def index
    @pagy, @medication_schedules = pagy(@medication.medication_schedules.active.order(:scheduled_time))
  end

  def new
    @medication_schedule = @medication.medication_schedules.build
  end

  def create
    @medication_schedule = @medication.medication_schedules.build(medication_schedule_params)

    respond_to do |format|
      if @medication_schedule.save
        format.html { redirect_to medication_url(id: @medication.id, locale: I18n.locale), notice: t(".success") }
      else
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  def destroy
    @medication_schedule = @medication.medication_schedules.find(params[:id])
    @medication_schedule.destroy

    respond_to do |format|
      format.html { redirect_to medication_url(id: @medication.id, locale: I18n.locale), notice: t(".success") }
    end
  end

  private

  def set_medication
    @medication = current_account.medications.find(params[:medication_id])
  end

  def medication_schedule_params
    params.expect(medication_schedule: %i[scheduled_time day_of_week time_of_day is_active])
  end
end
