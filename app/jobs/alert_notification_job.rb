class AlertNotificationJob < ApplicationJob
  queue_as :default

  def perform(alert_type, account_id, metadata = {})
    account = Account.find(account_id)

    case alert_type
    when "sos_alert"
      notify_specialists(account, "sos_alert", "SOS Alert", "#{account.full_name} triggered SOS!", metadata)
      notify_caregivers(account, "sos_alert", "Patient SOS Alert", "#{account.full_name} triggered SOS emergency!",
                        metadata)

    when "missed_medication"
      notify_specialists(account, "missed_medication", "Missed Medication",
                         "#{account.full_name} missed a medication dose", metadata)
      notify_caregivers(account, "missed_medication", "Medication Missed",
                        "#{account.full_name} missed a medication dose", metadata)

    when "low_adherence"
      notify_specialists(account, "low_adherence", "Low Adherence",
                         "#{account.full_name}'s adherence has dropped below 80%", metadata)

    when "abnormal_measurement"
      notify_specialists(account, "abnormal_measurement", "Abnormal Measurement",
                         "#{account.full_name} has an abnormal measurement: #{metadata[:value]}", metadata)
      notify_caregivers(account, "abnormal_measurement", "Abnormal Measurement",
                        "#{account.full_name} has an abnormal measurement", metadata)

    when "new_message"
      if metadata[:specialist_id]
        notify_specialist_of_reply(metadata[:specialist_id], account,
                                   "New Reply", "#{account.full_name} replied to your message", metadata)
      end

    when "recommendation_response"
      if metadata[:specialist_id]
        notify_specialist_of_reply(metadata[:specialist_id], account,
                                   "Recommendation Response",
                                   "#{account.full_name} responded to your recommendation", metadata)
      end
    end
  end

  private

  def notify_specialists(account, alert_type, title, message, metadata)
    account.specialist_patients.active.includes(:specialist).find_each do |sp|
      notification = SpecialistNotification.create!(
        specialist: sp.specialist,
        patient: account,
        notification_type: alert_type,
        title: title,
        message: message,
        notifiable: metadata[:notifiable]
      )

      SpecialistAlertsChannel.broadcast_to(
        sp.specialist,
        {
          id: notification.id,
          alert_type: alert_type,
          title: title,
          message: message,
          patient_name: account.full_name,
          patient_id: account.id,
          created_at: notification.created_at.iso8601
        }
      )
    end
  end

  def notify_caregivers(account, alert_type, title, message, metadata)
    account.caregivers.accepted.each do |cg|
      next unless should_notify_caregiver?(cg, alert_type)

      Notification.create!(
        account: cg.caregiver_account,
        title: title,
        body: message,
        notification_type: alert_type,
        notifiable: metadata[:notifiable]
      )

      NotificationsChannel.broadcast_to(
        cg.caregiver_account,
        {
          id: SecureRandom.uuid,
          type: alert_type,
          title: title,
          message: message,
          created_at: Time.current.iso8601
        }
      )
    end
  end

  def notify_specialist_of_reply(specialist_id, account, title, message, metadata)
    specialist = User.find(specialist_id)

    notification = SpecialistNotification.create!(
      specialist: specialist,
      patient: account,
      notification_type: "new_message",
      title: title,
      message: message,
      notifiable: metadata[:notifiable]
    )

    SpecialistMessagesChannel.broadcast_to(
      specialist,
      {
        id: notification.id,
        type: "new_message",
        title: title,
        message: message,
        patient_name: account.full_name,
        patient_id: account.id,
        created_at: notification.created_at.iso8601
      }
    )
  end

  def should_notify_caregiver?(caregiver, alert_type)
    case alert_type
    when "sos_alert", "abnormal_measurement"
      caregiver.notify_on_abnormal_measurement?
    when "missed_medication"
      caregiver.notify_on_missed_dose?
    when "low_adherence"
      caregiver.notify_on_low_adherence?
    else
      true
    end
  end
end
