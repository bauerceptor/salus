class Specialist::SchedulesController < Specialist::BaseController
  before_action :set_breadcrumbs

  def index
    @schedules = current_user.specialist.specialist_schedules.order(day_of_week: :asc, start_time: :asc)
    @appointments = current_user.specialist.specialist_appointments
                                .includes(:patient)
                                .where(appointment_date: Time.zone.today..(Time.zone.today + 30.days))
                                .order(appointment_date: :asc, start_time: :asc)

    @daily_appointments = @appointments.where(appointment_date: Time.zone.today)
    @weekly_appointments = @appointments.where(appointment_date: Time.zone.today.all_week)
    @monthly_appointments = @appointments.where(appointment_date: Time.zone.today.all_month)
  end

  def new
    @schedule = current_user.specialist.specialist_schedules.build
  end

  def edit
    @schedule = current_user.specialist.specialist_schedules.find(params[:id])
  end

  def create
    @schedule = current_user.specialist.specialist_schedules.build(schedule_params)
    if @schedule.save
      redirect_to specialist_schedules_path, notice: t(".success")
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @schedule = current_user.specialist.specialist_schedules.find(params[:id])
    if @schedule.update(schedule_params)
      redirect_to specialist_schedules_path, notice: t(".success")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @schedule = current_user.specialist.specialist_schedules.find(params[:id])
    @schedule.destroy
    redirect_to specialist_schedules_path, notice: t(".success")
  end

  private

  def schedule_params
    params.expect(specialist_schedule: %i[day_of_week start_time end_time appointment_type
                                          duration_minutes is_active])
  end

  def set_breadcrumbs
    add_breadcrumb t("breadcrumbs.home"), specialist_dashboard_path
    add_breadcrumb t(".breadcrumbs.schedule"), specialist_schedules_path
  end
end
