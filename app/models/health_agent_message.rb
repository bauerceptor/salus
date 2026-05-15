class HealthAgentMessage < ApplicationRecord
  belongs_to :conversation, class_name: "HealthAgentConversation"

  has_one_attached :attachment

  enum :role, { user: 0, assistant: 1, system: 2 }, prefix: :role

  validates :content, presence: true

  def attachment_data
    return nil unless attachment.attached?

    {
      "url" => url_for(attachment),
      "content_type" => attachment.content_type,
      "filename" => attachment.filename.to_s,
      "size" => attachment.byte_size
    }
  end
end
