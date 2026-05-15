class MedicationRequest < ApplicationRecord
  belongs_to :account
  belongs_to :specialist, class_name: "User", optional: true

  validates :medication_name, presence: true
  validates :status, inclusion: { in: %w[pending approved rejected] }

  before_validation :set_defaults, on: :create

  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :rejected, -> { where(status: "rejected") }
  scope :for_specialist, ->(specialist) { where(specialist_id: specialist.id) }

  def pending? = status == "pending"
  def approved? = status == "approved"
  def rejected? = status == "rejected"

  def approve!
    update!(status: "approved", reviewed_at: Time.current)
  end

  def reject!(reason = nil)
    update!(status: "rejected", rejection_reason: reason, reviewed_at: Time.current)
  end

  private

  def set_defaults
    self.status ||= "pending"
    self.requested_at ||= Time.current
  end
end
