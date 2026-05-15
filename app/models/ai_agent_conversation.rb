class AiAgentConversation < ApplicationRecord
  belongs_to :account, optional: false

  has_many :messages, class_name: "AiAgentMessage", foreign_key: "conversation_id", dependent: :destroy

  validates :account_id, presence: true

  def last_message_preview
    last = messages.order(created_at: :desc).first
    last&.content&.truncate(50)
  end
end
