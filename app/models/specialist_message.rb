# == Schema Information
#
# Table name: specialist_messages
#
#  id                       :uuid             not null, primary key
#  account_id               :uuid             not null, primary key
#  body                     :text             not null
#  is_read                  :boolean          default(FALSE), not null
#  parent_id                :uuid
#  sender_type              :string           not null
#  specialist_id            :uuid             not null, primary key
#  specialist_recommendation_id :uuid
#  subject                  :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
# Indexes
#
#  index_specialist_messages_on_specialist_id_and_account_id  (specialist_id,account_id)
#  index_specialist_messages_on_sender_type                   (sender_type)
#  index_specialist_messages_on_is_read                       (is_read)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (parent_id => specialist_messages.id)
#  fk_rails_...  (specialist_id => users.id)
#  fk_rails_...  (specialist_recommendation_id => specialist_recommendations.id)
#
class SpecialistMessage < ApplicationRecord
  belongs_to :specialist, class_name: "User"
  belongs_to :account
  belongs_to :parent, class_name: "SpecialistMessage", optional: true
  belongs_to :specialist_recommendation, optional: true

  has_many :attachments, class_name: "MessageAttachment", foreign_key: "message_id", dependent: :destroy

  SENDER_TYPES = %w[specialist patient].freeze

  validates :sender_type, inclusion: { in: SENDER_TYPES }
  validates :subject, presence: true, length: { maximum: 255 }
  validates :body, presence: true, length: { maximum: 5000 }

  after_create :notify_recipient, :queue_knowledge_distillation

  scope :unread, -> { where(is_read: false) }
  scope :for_account, ->(account) { where(account_id: account.id) }
  scope :from_specialist, -> { where(sender_type: "specialist") }
  scope :from_patient, -> { where(sender_type: "patient") }
  scope :conversation, lambda { |account_id, specialist_id|
    where(account_id: account_id, specialist_id: specialist_id)
      .or(where(account_id: account_id, parent_id: SpecialistMessage.where(account_id: account_id, specialist_id: specialist_id).select(:id)))
      .order(created_at: :asc)
  }

  def mark_as_read!
    update!(is_read: true) unless is_read?
  end

  def reply_from_specialist?
    sender_type == "specialist"
  end

  def reply_from_patient?
    sender_type == "patient"
  end

  def other_party_name
    if reply_from_specialist?
      account.full_name
    else
      specialist.account.full_name
    end
  end

  def attachments?
    attachments.any?
  end

  def queue_knowledge_distillation
    KnowledgeDistillationJob.perform_later(id)
  end

  private

  def notify_recipient
    if reply_from_specialist?
      Notification.create!(
        account: account,
        title: "New Message from Dr. #{specialist.account.full_name}",
        body: subject,
        notification_type: "specialist_message",
        notifiable: self
      )

      SpecialistMessagesChannel.broadcast_to(
        account,
        {
          id: id,
          type: "specialist_message",
          subject: subject,
          sender_name: "Dr. #{specialist.account.full_name}",
          specialist_id: specialist_id,
          body: body,
          created_at: created_at.iso8601,
          attachments: attachments.map { |a| { file_type: a.file_type, url: a.url, filename: a.filename } }
        }
      )
    else
      SpecialistNotification.create!(
        specialist: specialist,
        patient: account,
        notification_type: "new_message",
        title: "New Reply",
        message: "#{account.full_name}: #{subject}",
        notifiable: self
      )

      SpecialistMessagesChannel.broadcast_to(
        specialist,
        {
          id: id,
          type: "new_message",
          subject: subject,
          sender_name: account.full_name,
          patient_id: account_id,
          body: body,
          created_at: created_at.iso8601,
          attachments: attachments.map { |a| { file_type: a.file_type, url: a.url, filename: a.filename } }
        }
      )
    end
  end
end
