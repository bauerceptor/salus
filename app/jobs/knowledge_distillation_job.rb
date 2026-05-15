class KnowledgeDistillationJob < ApplicationJob
  queue_as :health_agent

  def perform(specialist_message_id)
    return if specialist_message_id.nil?

    message = SpecialistMessage.find_by(id: specialist_message_id)
    return unless message
    return unless should_process?(message)

    deidentified_content = anonymize(message)

    RubyLLM.embed(deidentified_content)

    HealthEmbedding.embed_and_store(
      content: deidentified_content,
      embedding_type: HealthEmbedding::EMBEDDING_TYPES[:anonymized_pattern],
      account: message.account,
      metadata: {
        specialist_id: message.specialist_id,
        sender_type: message.sender_type,
        created_at: message.created_at,
        message_type: infer_message_type(message)
      }
    )
  end

  private

  def anonymize(message)
    text = message.body.dup

    text.gsub!(message.account.full_name, "[Patient]")
    text.gsub!(message.account.first_name, "[Patient]") if message.account.first_name.present?
    text.gsub!(message.account.last_name, "[Patient]") if message.account.last_name.present?

    specialist_name = message.specialist.account.full_name
    text.gsub!(specialist_name, "[Specialist]")
    text.gsub!(message.specialist.account.first_name, "[Specialist]") if message.specialist.account.first_name.present?
    text.gsub!(message.specialist.account.last_name, "[Specialist]") if message.specialist.account.last_name.present?

    text
  end

  def should_process?(message)
    return false if message.body.blank?
    return false if message.body.length < 20

    true
  end

  def infer_message_type(message)
    case message.body
    when /fatigue|dizziness|headache|pain|nausea/i
      "symptom_report"
    when /medication|dose|prescription/i
      "medication_inquiry"
    when /question|how come|why/i
      "general_inquiry"
    else
      "general_communication"
    end
  end
end
