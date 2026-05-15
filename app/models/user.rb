# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  email                  :string           default(""), not null
#  password_digest         :string           default(""), not null
#  reset_password_token    :string
#  reset_password_sent_at  :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
class User < ApplicationRecord
  include Roleable

  has_secure_password

  has_one :account, dependent: :destroy
  has_one :specialist, dependent: :destroy, inverse_of: :user, required: false

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  has_many :specialist_patients, foreign_key: :specialist_id, dependent: :destroy
  has_many :specialist_notes, foreign_key: :specialist_id, dependent: :destroy
  has_many :specialist_recommendations, foreign_key: :specialist_id, dependent: :destroy
  has_many :specialist_messages, foreign_key: :specialist_id, dependent: :destroy
  has_many :specialist_notifications, foreign_key: :specialist_id, dependent: :destroy
  has_many :medication_requests, foreign_key: :specialist_id, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :tos_agreement, acceptance: true, on: :create

  after_create :set_patient_role!

  def otp_enabled?
    otp_required_for_login?
  end

  def enable_two_factor!
    update!(
      otp_required_for_login: true,
      otp_secret: User.generate_otp_secret
    )
  end

  def disable_two_factor!
    update!(
      otp_required_for_login: false,
      otp_secret: nil,
      otp_backup_codes: nil
    )
  end

  def two_factor_provisioning_uri(secret)
    totp = ROTP::TOTP.new(secret, issuer: "Salus")
    totp.provisioning_uri(email)
  end

  def two_factor_otp_qrcode(uri)
    RQRCode::QRCode.new(uri)
  end

  def generate_two_factor_secret_if_missing!
    return if otp_secret.present?

    update!(otp_secret: User.generate_otp_secret)
  end

  def generate_otp_backup_codes!
    codes = Array.new(10) { SecureRandom.hex(8) }
    update!(otp_backup_codes: codes.join("\n"))
  end

  def two_factor_backup_codes_generated?
    otp_backup_codes.present?
  end

  def generate_reset_password_token!
    update!(
      reset_password_token: SecureRandom.urlsafe_base64(48),
      reset_password_sent_at: Time.current
    )
  end

  def reset_password_token_valid?
    reset_password_sent_at && reset_password_sent_at > 2.hours.ago
  end

  def clear_reset_password_token!
    update!(
      reset_password_token: nil,
      reset_password_sent_at: nil
    )
  end

  def oauth_account?
    false
  end

  def self.generate_otp_secret
    ROTP::Base32.random
  end
end
