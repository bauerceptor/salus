class HealthAgentConversation < ApplicationRecord
  belongs_to :account, optional: false

  has_many :messages, lambda {
    order(created_at: :asc)
  }, class_name: "HealthAgentMessage", dependent: :destroy, foreign_key: "conversation_id"

  enum :persona, { patient: 0, specialist: 1 }, prefix: :persona
  enum :status, { active: 0, archived: 1 }, prefix: :status, default: :active

  validates :account_id, presence: true

  def last_message_preview
    last = messages.order(created_at: :desc).first
    last&.content&.truncate(50)
  end
end
