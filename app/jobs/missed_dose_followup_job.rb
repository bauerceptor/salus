class MissedDoseFollowupJob < ApplicationJob
  queue_as :default

  WINDOW_HOURS = ENV.fetch("MISSED_DOSE_FOLLOWUP_WINDOW_HOURS", "4").to_i

  def perform
    window_start = WINDOW_HOURS.hours.ago
    missed_logs = MedicationLog.missed
                              .where("scheduled_for >= ?", window_start)
                              .includes(:account, :medication)

    processed_ids = Set.new

    missed_logs.each do |log|
      next if processed_ids.include?(log.id)
      next if already_followed_up?(log)

      conversation = HealthAgentConversation.find_or_create_by!(
        account: log.account,
        persona: :patient,
        status: :active
      )

      response = ProactiveAgentService.call(
        prompt: build_followup_prompt(log),
        account: log.account
      )

      next unless response

      message = HealthAgentMessage.create!(
        conversation: conversation,
        role: :assistant,
        content: response
      )

      mark_followed_up(log)
      processed_ids.add(log.id)
      broadcast_to_account(log.account, message)
    rescue StandardError => e
      Rails.logger.error("[MissedDoseFollowupJob] Failed for log #{log.id}: #{e.message}")
    end
  end

  private

  def build_followup_prompt(log)
    med_name = log.medication.name
    dosage = log.medication.dosage

    "A patient missed their dose of #{med_name} (#{dosage}). " \
      "Send a brief, supportive message checking in on them. " \
      "Ask if they would like help remembering to take it. " \
      "Do not be judgmental. Keep it warm and encouraging, 1-2 sentences max."
  end

  def already_followed_up?(log)
    false
  end

  def mark_followed_up(log)
  end

  def broadcast_to_account(account, message)
    NotificationsChannel.broadcast_to(
      account,
      {
        id: message.id,
        type: "missed_dose_followup",
        content: message.content.truncate(100),
        created_at: message.created_at.iso8601
      }
    )
  end
end
