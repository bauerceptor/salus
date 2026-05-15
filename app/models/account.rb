# == Schema Information
#
# Table name: accounts
#
#  id           :uuid             not null, primary key
#  bio          :text             default(""), not null
#  birthday     :date
#  city         :string           default(""), not null
#  country      :string           default(""), not null
#  education    :string           default(""), not null
#  first_name   :string           default(""), not null
#  image_data   :text
#  is_hidden    :boolean          default(FALSE), not null
#  is_verified  :boolean          default(FALSE), not null
#  last_name    :string           default(""), not null
#  phone_number :string           default(""), not null
#  settings     :jsonb            not null
#  sex          :string           default(""), not null
#  username     :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :uuid             not null
#
# Indexes
#
#  index_accounts_on_settings  (settings) USING gin
#  index_accounts_on_user_id   (user_id)
#  index_accounts_on_username  (username) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Account < ApplicationRecord
  include ImageUploader::Attachment(:image)
  include ImageUploader::Attachment(:background)

  belongs_to :user

  has_many :friend_requests, dependent: :destroy
  has_many :sent_friend_requests, class_name: "FriendRequest",
                                  dependent: :destroy
  has_many :received_friend_requests, class_name: "FriendRequest", foreign_key: :friend_id,
                                      dependent: :destroy, inverse_of: :friend

  has_many :friendships, dependent: :destroy
  has_many :friends, through: :friendships

  def linked_specialists
    specialist_patients.active.includes(specialist: :account).map { |sp| sp.specialist.account }.compact
  end

  has_many :group_members, dependent: :destroy
  has_many :groups, through: :group_members
  has_many :group_posts, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :post_bookmarks, dependent: :destroy
  has_many :bookmarked_posts, through: :post_bookmarks, source: :post

  has_many :diseases, dependent: :destroy
  has_many :treatments, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :note_groups, dependent: :destroy
  has_many :note_tags, dependent: :destroy
  has_many :measurements, dependent: :destroy
  has_many :measurement_raports, dependent: :destroy
  has_many :medications, dependent: :destroy
  has_many :medication_logs, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :emergency_alerts, dependent: :destroy
  has_many :ai_agent_conversations, dependent: :destroy
  has_many :health_agent_conversations, dependent: :destroy
  has_many :behavior_sequences, dependent: :destroy
  has_many :caregivers, dependent: :destroy
  has_many :shared_accesses, dependent: :destroy
  has_many :caregivers_as_caregiver, class_name: "Caregiver", foreign_key: :caregiver_account_id, dependent: :destroy

  has_many :specialist_requests, dependent: :destroy
  has_many :articles, dependent: :destroy
  has_many :treatment_requests, dependent: :destroy
  has_many :specialist_messages, dependent: :destroy
  has_many :specialist_notifications, dependent: :destroy
  has_many :specialist_notes, dependent: :destroy
  has_many :specialist_recommendations, dependent: :destroy
  has_many :specialist_patients, dependent: :destroy
  has_many :karma_points, dependent: :destroy

  enum :badge, { newcomer: 0, contributor: 1, advocate: 2, expert: 3 }, prefix: true

  BADGE_TIERS = {
    newcomer: 0,
    contributor: 11,
    advocate: 51,
    expert: 101
  }.freeze

  EDUCATION_OPTIONS = %w[none primary secondary bachelor master doctorate].freeze
  SEX_OPTIONS = %w[male female other].freeze

  PRIVACY_DEFAULTS = {
    profile_visibility: "friends",
    show_health_data: false,
    allow_friend_requests: true,
    show_online_status: true,
    shareMeasurements: false
  }.freeze

  VALID_PRIVACY_VALUES = {
    profile_visibility: %w[public friends private],
    show_health_data: [true, false, "true", "false"],
    allow_friend_requests: [true, false, "true", "false"],
    show_online_status: [true, false, "true", "false"],
    share_measurements: [true, false, "true", "false"]
  }.freeze

  def privacy_settings
    settings.with_defaults(PRIVACY_DEFAULTS)
  end

  def update_privacy_settings(privacy_params)
    return false unless valid_privacy_settings?(privacy_params)
    new_settings = privacy_settings.merge(privacy_params.stringify_keys)
    update(settings: new_settings)
  end

  DISMISSED_NUDGE_DEFAULTS = {
    dismissed_group_nudge_ids: []
  }.freeze

  def dismissed_nudge_settings
    settings.symbolize_keys.with_defaults(DISMISSED_NUDGE_DEFAULTS)
  end

  def dismissed_nudge_ids
    dismissed_nudge_settings[:dismissed_group_nudge_ids]
  end

  def dismiss_nudge!(nudge_id)
    nudge_ids = (dismissed_nudge_settings[:dismissed_group_nudge_ids] || []).dup
    return if nudge_ids.include?(nudge_id)

    nudge_ids << nudge_id
    new_settings = dismissed_nudge_settings.merge(dismissed_group_nudge_ids: nudge_ids)
    update!(settings: new_settings.stringify_keys)
    reload
  end

  def nudge_dismissed?(nudge_id)
    (dismissed_nudge_settings[:dismissed_group_nudge_ids] || []).include?(nudge_id)
  end

  validates :first_name, presence: true, length: { maximum: 32 }
  validates :last_name, presence: true, length: { maximum: 32 }
  validates :username, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :bio, length: { maximum: 100 }, allow_blank: true
  validates :sex, inclusion: { in: SEX_OPTIONS }, allow_blank: true
  validates :country, length: { maximum: 50 }, allow_blank: true
  validates :city, length: { maximum: 50 }, allow_blank: true
  validates :phone_number, phone: { allow_blank: true }
  validates :education, inclusion: {
                          in: EDUCATION_OPTIONS
                        },
                        allow_blank: true
  validates :sex, inclusion: { in: SEX_OPTIONS }, allow_blank: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def badge_level
    case karma_score
    when 0..10 then :newcomer
    when 11..50 then :contributor
    when 51..100 then :advocate
    else :expert
    end
  end

  def recompute_badge!
    new_badge = badge_level
    update!(badge: new_badge) if send(:badge) != new_badge
  end

  def account_incomplete?
    first_name.blank? || last_name.blank? || username.blank?
  end

  # Friendship methods

  def all_friend_requests
    FriendRequest.where(
      "account_id = :account_id OR friend_id = :account_id", account_id: id
    )
  end

  def friend?(account)
    friends.exists?(account.id)
  end

  def friend_request_sent?(account)
    sent_friend_requests.exists?(friend_id: account.id)
  end

  def friend_request_received?(account)
    received_friend_requests.exists?(account_id: account.id)
  end

  # Chat methods
  def chatrooms
    Chatroom.where("account1_id = ? OR account2_id = ?", id, id)
  end

  def chat_with(other_account)
    Chatroom.find_by("account1_id = ? AND account2_id = ?", other_account.id, id) ||
    Chatroom.find_by("account1_id = ? AND account2_id = ?", id, other_account.id)
  end

  def update_presence(status:, chatroom: nil)
    update!(
      online_status: status,
      last_seen_at: Time.current,
      typing_in_chatroom_id: chatroom&.id
    )
  end

  def other_accounts
    Account.where.not(id: id)
  end

  scope :high_risk, -> { where("risk_score >= ?", 50) }
  scope :moderate_risk, -> { where("risk_score >= ? AND risk_score < ?", 25, 50) }
  scope :low_risk, -> { where("risk_score < ?", 25) }

  def risk_level
    case
    when risk_score >= 50 then "HIGH"
    when risk_score >= 25 then "MODERATE"
    else "LOW"
    end
  end

  def care_team
    caregivers.accepted
  end

  def caregivers_as_caregiver_list
    caregivers_as_caregiver.accepted
  end

  def primary_emergency_contact
    emergency_contacts.primary.first
  end

  def trigger_sos(message: nil)
    contact = primary_emergency_contact
    return false unless contact

    alert = emergency_alerts.create!(
      emergency_contact: contact,
      alert_type: EmergencyAlert::ALERT_TYPES[:sos_button],
      message: message || "Emergency SOS triggered by #{full_name}",
      status: EmergencyAlert::STATUSES[:pending]
    )

    Notification.create!(
      account: self,
      title: "Emergency SOS Sent",
      body: "Emergency contact #{contact.name} has been notified.",
      notification_type: "emergency_alert",
      notifiable: alert
    )

    alert
  end

  def check_abnormal_measurement(measurement)
    return nil unless measurement.abnormal?

    threshold_key = "#{measurement.measurement_type.name.downcase}_threshold"
    threshold = measurement.measurement_type.send(threshold_key) rescue nil

    alert = emergency_alerts.create!(
      alert_type: EmergencyAlert::ALERT_TYPES[:abnormal_measurement],
      message: "Abnormal #{measurement.measurement_type.name}: #{measurement.value} (threshold: #{threshold || 'N/A'})",
      status: EmergencyAlert::STATUSES[:pending],
      triggered_by: measurement
    )

    Notification.create!(
      account: self,
      title: "Abnormal Measurement Detected",
      body: alert.message,
      notification_type: "measurement_alert",
      notifiable: alert
    )

    alert
  end

  private

  def valid_privacy_settings?(params)
    params.each do |key, value|
      valid_options = VALID_PRIVACY_VALUES[key.to_sym]
      return false unless valid_options && valid_options.include?(value)
    end
    true
  end

  def profile_visibility
    privacy_settings[:profile_visibility]
  end

  def show_health_data?
    privacy_settings[:show_health_data]
  end

  def allow_friend_requests?
    privacy_settings[:allow_friend_requests]
  end

  def show_online_status?
    privacy_settings[:show_online_status]
  end

  def share_measurements?
    privacy_settings[:share_measurements]
  end
end
