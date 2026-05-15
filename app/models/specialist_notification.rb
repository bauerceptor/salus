# == Schema Information
#
# Table name: specialist_notifications
#
#  id                 :uuid             not null, primary key
#  is_read            :boolean          default(FALSE), not null
#  message            :text
#  notifiable_id      :uuid
#  notifiable_type    :string
#  notification_type  :string           not null
#  patient_id         :uuid             not null, FK -> accounts.id
#  specialist_id      :uuid             not null, FK -> users.id
#  title              :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_specialist_notifications_on_specialist_id_and_is_read  (specialist_id,is_read)
#  index_specialist_notifications_on_notification_type         (notification_type)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => accounts.id)
#  fk_rails_...  (specialist_id => users.id)
#
class SpecialistNotification < ApplicationRecord
  belongs_to :specialist, class_name: "User"
  belongs_to :patient, class_name: "Account"
  belongs_to :notifiable, polymorphic: true, optional: true

  NOTIFICATION_TYPES = %w[
    sos_alert
    missed_medication
    low_adherence
    abnormal_measurement
    new_message
    recommendation_response
  ].freeze

  validates :notification_type, inclusion: { in: NOTIFICATION_TYPES }

  scope :unread, -> { where(is_read: false) }
  scope :for_specialist, ->(specialist) { where(specialist_id: specialist.id) }
  scope :recent, -> { order(created_at: :desc).limit(50) }
  scope :unacknowledged, -> { where(acknowledged_at: nil) }
  scope :critical, -> { where(notification_type: %w[sos_alert abnormal_measurement]) }
  scope :warning, -> { where(notification_type: %w[missed_medication low_adherence]) }
  scope :info, -> { where(notification_type: %w[new_message recommendation_response]) }

  def acknowledge!(specialist:)
    raise ArgumentError, "Not authorized" unless acknable_by?(specialist)

    update!(acknowledged_at: Time.current)
  end

  def acknable_by?(specialist)
    specialist_patient&.specialist_id == specialist.id
  end

  def acknowledged?
    acknowledged_at.present?
  end

  def severity
    case notification_type
    when "sos_alert", "abnormal_measurement" then :critical
    when "missed_medication", "low_adherence" then :warning
    else :info
    end
  end

  def specialist_patient
    return @specialist_patient if defined?(@specialist_patient)

    @specialist_patient = SpecialistPatient.find_by(specialist_id: specialist_id, account_id: patient_id)
  end

  def mark_as_read!
    update!(is_read: true) unless is_read?
  end

  def notification_icon
    case notification_type
    when "sos_alert" then "ri-alarm-warning-line"
    when "missed_medication" then "ri-pill-line"
    when "low_adherence" then "ri-line-chart-line"
    when "abnormal_measurement" then "ri-heart-pulse-line"
    when "new_message" then "ri-message-3-line"
    when "recommendation_response" then "ri-heart-pulse-line"
    else "ri-notification-3-line"
    end
  end

  def notification_color
    case notification_type
    when "sos_alert", "abnormal_measurement" then "red"
    when "missed_medication", "low_adherence" then "yellow"
    else "blue"
    end
  end
end
