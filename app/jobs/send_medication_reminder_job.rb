class SendMedicationReminderJob < ApplicationJob
  queue_as :default

  def perform
    upcoming_logs = MedicationLog.pending
                                 .where(scheduled_for: Time.current..1.hour.from_now)
                                 .includes(:medication, :account)

    upcoming_logs.each do |log|
      next unless log.medication.is_active?

      Notification.create(
        account: log.account,
        title: I18n.t("notifications.medication_reminder.title"),
        body: I18n.t("notifications.medication_reminder.body",
                     medication_name: log.medication.name,
                     dosage: log.medication.dosage),
        notification_type: "medication_reminder",
        notifiable: log
      )

      broadcast_notification(log.account, log)
    end
  end

  private

  def broadcast_notification(account, log)
    NotificationsChannel.broadcast_to(
      account,
      {
        id: log.id,
        medication_name: log.medication.name,
        dosage: log.medication.dosage,
        scheduled_for: log.scheduled_for,
        type: "medication_reminder"
      }
    )
  end
end
