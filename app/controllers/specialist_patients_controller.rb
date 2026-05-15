class SpecialistPatientsController < BaseController
  def create
    specialist = User.find(params[:specialist_id])
    account = current_account

    existing = SpecialistPatient.find_by(specialist: specialist, account: account)

    if existing
      redirect_to specialists_path, alert: "You already have a request with this specialist."
    else
      SpecialistPatient.create!(
        specialist: specialist,
        account: account,
        status: "pending"
      )
      redirect_to specialists_path, notice: "Request sent to Dr. #{specialist.account.full_name}."
    end
  end

  def request_appointment
    specialist_user = User.find(params[:specialist_id])
    specialist = Specialist.find_by(user: specialist_user)
    account = current_account

    if specialist.nil?
      redirect_to patient_messages_path, alert: "Specialist not found."
      return
    end

    specialist_patient = SpecialistPatient.active.find_by(specialist: specialist_user, account: account)

    if specialist_patient.nil?
      redirect_to patient_messages_path, alert: "You don't have an active connection with this doctor."
      return
    end

    schedule = SpecialistSchedule.find_by(id: params[:schedule_id])

    if schedule.nil?
      redirect_to patient_messages_path, alert: "Invalid schedule selected."
      return
    end

    appointment_date = Date.parse(params[:appointment_date])
    start_time = Time.zone.parse("#{params[:appointment_date]} #{params[:start_time]}")
    end_time = start_time + schedule.duration_minutes.minutes

    SpecialistAppointment.create!(
      specialist: specialist,
      patient: account,
      schedule: schedule,
      appointment_date: appointment_date,
      start_time: start_time.strftime("%H:%M"),
      end_time: end_time.strftime("%H:%M"),
      status: :scheduled,
      notes: params[:notes]
    )

    redirect_to patient_messages_path, notice: "Appointment request sent! Your doctor will confirm shortly."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to patient_messages_path, alert: "Failed to create appointment: #{e.message}"
  rescue Date::Error, ArgumentError
    redirect_to patient_messages_path, alert: "Invalid date or time format."
  end
end
