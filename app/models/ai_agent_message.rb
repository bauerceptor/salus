class AiAgentMessage < ApplicationRecord
  belongs_to :conversation, class_name: "AiAgentConversation"

  validates :role, presence: true, inclusion: { in: %w[user assistant system] }
  validates :content, presence: true, unless: -> { attachments.present? && attachments.any? }

  def attachment_data
    self[:attachments].presence || {}
  end
end
