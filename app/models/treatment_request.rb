# == Schema Information
#
# Table name: treatment_requests
#
#  id               :uuid             not null, primary key
#  account_id        :uuid             not null
#  description       :text             default(""), not null
#  rejection_reason  :text             default(""), not null
#  requested_at      :datetime         not null
#  reviewed_at       :datetime
#  specialist_id     :uuid
#  start_date        :date
#  status            :string           default("pending"), not null
#  title             :string           default(""), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class TreatmentRequest < ApplicationRecord
  belongs_to :account
  belongs_to :specialist, class_name: "User", optional: true

  STATUSES = %w[pending approved rejected].freeze

  validates :title, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }
  validates :status, inclusion: { in: STATUSES }
  validate :start_date_within_allowed_range, if: :start_date_present?

  def start_date_present?
    start_date.present?
  end

  def start_date_within_allowed_range
    return if start_date.blank?

    if start_date > 3.days.from_now.to_date
      errors.add(:start_date, :too_far_in_future)
    elsif start_date < 3.days.ago.to_date
      errors.add(:start_date, :too_old)
    end
  end

  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :rejected, -> { where(status: "rejected") }
  scope :for_account, ->(account) { where(account_id: account.id) }
  scope :recent_pending, -> { pending.where(requested_at: 30.days.ago..).order(requested_at: :desc) }

  before_validation :set_defaults, on: :create

  def pending?
    status == "pending"
  end

  def approved?
    status == "approved"
  end

  def rejected?
    status == "rejected"
  end

  def approve!(specialist_user)
    update!(
      status: "approved",
      specialist_id: specialist_user.id,
      reviewed_at: Time.current
    )
  end

  def reject!(specialist_user, reason = nil)
    update!(
      status: "rejected",
      specialist_id: specialist_user.id,
      rejection_reason: reason,
      reviewed_at: Time.current
    )
  end

  private

  def set_defaults
    self.status ||= "pending"
    self.requested_at ||= Time.current
  end
end
