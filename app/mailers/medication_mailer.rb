class MedicationMailer < ApplicationMailer
  def reminder
    @account = params[:account]
    @medication = params[:medication]
    @scheduled_time = params[:scheduled_time]

    mail to: @account.user.email,
         subject: I18n.t("medication_mailer.reminder.subject",
                         medication_name: @medication.name)
  end

  def missed_dose
    @account = params[:account]
    @medication = params[:medication]

    mail to: @account.user.email,
         subject: I18n.t("medication_mailer.missed_dose.subject",
                         medication_name: @medication.name)
  end
end
