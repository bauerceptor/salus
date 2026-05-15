# == Schema Information
#
# Table name: emergency_alerts
#
#  id                  :uuid             not null, primary key
#  account_id          :uuid             not null, primary key
#  acknowledged_at     :datetime
#  alert_type         :string           not null
#  emergency_contact_id :uuid
#  message             :text
#  status              :integer          default("0"), not null
#  triggered_by_id     :uuid
#  triggered_by_type   :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_emergency_alerts_on_account_id             (account_id)
#  index_emergency_alerts_on_emergency_contact_id    (emergency_contact_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (emergency_contact_id => emergency_contacts.id)
#
class EmergencyAlert < ApplicationRecord
  belongs_to :account
  belongs_to :emergency_contact, optional: true
  belongs_to :triggered_by, polymorphic: true, optional: true

  after_create :notify_care_team

  validates :alert_type, presence: true

  ALERT_TYPES = {
    sos_button: "sos_button",
    missed_medication: "missed_medication",
    abnormal_measurement: "abnormal_measurement",
    low_adherence: "low_adherence",
    no_activity: "no_activity"
  }.freeze

  STATUSES = {
    pending: 0,
    sent: 1,
    acknowledged: 2,
    resolved: 3,
    expired: 4
  }.freeze

  scope :active, -> { where(status: [STATUSES[:pending], STATUSES[:sent]]) }
  scope :for_account, ->(account) { where(account_id: account.id) }
  scope :unacknowledged, -> { where(status: [STATUSES[:pending], STATUSES[:sent]]) }

  def pending?
    status == STATUSES[:pending]
  end

  def sent?
    status == STATUSES[:sent]
  end

  def acknowledged?
    status == STATUSES[:acknowledged]
  end

  def resolved?
    status == STATUSES[:resolved]
  end

  def acknowledge
    update(status: STATUSES[:acknowledged], acknowledged_at: Time.current)
  end

  def resolve
    update(status: STATUSES[:resolved])
  end

  def escalate
    alert_type_value = ALERT_TYPES.value?(alert_type) ? alert_type : ALERT_TYPES[:sos_button]
    EmergencyAlert.create!(
      account: account,
      alert_type: alert_type_value,
      status: STATUSES[:pending],
      message: "ESCALATED: #{message}",
      triggered_by: triggered_by
    )
  end

  private

  def notify_care_team
    AlertNotificationJob.perform_later(
      alert_type,
      account_id,
      {
        notifiable: self,
        triggered_by_type: triggered_by_type,
        triggered_by_id: triggered_by_id,
        message: message
      }
    )
  end
end
