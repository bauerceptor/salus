class DailyHealthCheckinJob < ApplicationJob
  queue_as :default

  def perform
    Account.find_each do |account|
      next unless account.medications.active.any? || account.measurements.any?

      conversation = HealthAgentConversation.find_or_create_by!(
        account: account,
        persona: :patient,
        status: :active
      )

      response = ProactiveAgentService.call(
        prompt: "Send a warm, brief morning check-in message to your patient. " \
                "Ask how they are feeling today and if they noticed any symptoms. " \
                "Keep it conversational and encouraging. Maximum 2-3 sentences.",
        account: account
      )

      next unless response

      message = HealthAgentMessage.create!(
        conversation: conversation,
        role: :assistant,
        content: response
      )

      broadcast_to_account(account, message)
    rescue StandardError => e
      Rails.logger.error("[DailyHealthCheckinJob] Failed for account #{account.id}: #{e.message}")
    end
  end

  private

  def broadcast_to_account(account, message)
    NotificationsChannel.broadcast_to(
      account,
      {
        id: message.id,
        type: "proactive_checkin",
        content: message.content.truncate(100),
        created_at: message.created_at.iso8601
      }
    )
  end
end
