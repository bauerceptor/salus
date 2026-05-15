class SpecialistFeedbackJob < ApplicationJob
  queue_as :health_agent

  def perform(alert_id, action_taken)
    return if alert_id.nil?

    alert = EmergencyAlert.find_by(id: alert_id)
    return unless alert

    RubyLLM.embed(build_feedback_context(alert, action_taken))

    HealthEmbedding.embed_and_store(
      content: build_feedback_context(alert, action_taken),
      embedding_type: HealthEmbedding::EMBEDDING_TYPES[:anonymized_pattern],
      account: alert.account,
      metadata: {
        alert_type: alert.alert_type,
        action: action_taken,
        triggered_at: alert.created_at,
        feedback_at: Time.current
      }
    )
  end

  private

  def build_feedback_context(alert, action_taken)
    <<~TEXT
      Specialist #{action_taken} alert: #{alert.alert_type}
      Original message: #{alert.message}
      Action taken: #{action_taken}
      Alert triggered at: #{alert.created_at.iso8601}
      Feedback recorded at: #{Time.current.iso8601}
    TEXT
  end
end
