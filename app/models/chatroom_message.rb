class ChatroomMessage < ApplicationRecord
  belongs_to :account
  belongs_to :chatroom
  belongs_to :reply_to_message, class_name: "ChatroomMessage", optional: true

  has_one_attached :attachment

  enum :message_type, {
    text: 0,
    photo: 1,
    video: 2,
    audio: 3,
    document: 4,
    voice_note: 5
  }

  validates :body, presence: true, unless: :attachment?
  validate :voice_note_has_attachment, if: :voice_note?
  validate :attachment_size_limit, if: :voice_note?

  MAX_VOICE_NOTE_SIZE = 10.megabytes

  def attachment?
    attachment.attached?
  end

  def voice_note?
    message_type == :voice_note
  end

  delegate :other_participant, to: :chatroom

  def read_by?(account)
    read_at.present? && account.id != account_id
  end

  private

  def voice_note_has_attachment
    return if attachment.attached?

    errors.add(:attachment, "must be attached for voice notes")
  end

  def attachment_size_limit
    return unless attachment.attached? && attachment.byte_size > MAX_VOICE_NOTE_SIZE

    errors.add(:attachment, "must be less than 10MB")
  end
end
