# == Schema Information
#
# Table name: treatments
#
#  id                             :uuid             not null, primary key
#  account_id                     :uuid             not null
#  approval_status                :string           default: "pending", not null
#  approved_at                    :datetime
#  approved_by_id                 :uuid
#  created_at                     :datetime         not null
#  description                    :text             default: "", not null
#  effectiveness                  :integer          default: 0, not null
#  end_date                       :date
#  hidden_at                      :datetime
#  is_finished                    :boolean          default: FALSE, not null
#  is_hidden                      :boolean          default: FALSE, not null
#  name                           :string           default: "", not null
#  requested_at                   :datetime
#  source                         :string
#  specialist_recommendation_id   :uuid
#  start_date                     :date
#  status                         :string           default: "active"
#  title                          :string           default: "", not null
#  updated_at                     :datetime         not null
#
# Indexes
#
#  index_treatments_on_account_id  (account_id)
#  index_treatments_on_source      (source)
#  index_treatments_on_specialist_recommendation_id  (specialist_recommendation_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Treatment < ApplicationRecord
  SOURCE_TYPES = %w[patient_request doctor_prescription].freeze

  belongs_to :account
  belongs_to :specialist_recommendation, class_name: "SpecialistRecommendation", optional: true

  has_many :updates, class_name: "TreatmentUpdate", inverse_of: :treatment, dependent: :destroy

  has_many :treatment_diseases, dependent: :destroy
  has_many :diseases, through: :treatment_diseases

  validates :title, length: { maximum: 100 }, presence: true
  validates :description, length: { maximum: 500 }, presence: true
  validates :effectiveness, presence: true,
                            numericality: {
                              only_integer: true,
                              greater_than_or_equal_to: 1,
                              less_than_or_equal_to: 5
                            }
  validates :start_date, presence: true
  validates :approval_status, inclusion: { in: %w[pending approved rejected] }
  validates :source, inclusion: { in: SOURCE_TYPES }, allow_nil: true
  validate :start_date_within_allowed_range
  validate :end_date_within_allowed_range, if: :end_date_present?
  validate :end_date_after_start_date, if: :both_dates_present?

  def end_date_present?
    end_date.present?
  end

  def both_dates_present?
    start_date.present? && end_date.present?
  end

  def start_date_within_allowed_range
    return if start_date.blank?

    if start_date > 3.days.from_now.to_date
      errors.add(:start_date, :too_far_in_future)
    elsif start_date < 3.days.ago.to_date
      errors.add(:start_date, :too_old)
    end
  end

  def end_date_within_allowed_range
    return if end_date.blank?

    if end_date > 3.days.from_now.to_date
      errors.add(:end_date, :too_far_in_future)
    elsif end_date < 3.days.ago.to_date
      errors.add(:end_date, :too_old)
    end
  end

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    if end_date < start_date
      errors.add(:end_date, :must_be_after_start_date)
    end
  end

  scope :pending, -> { where(approval_status: "pending") }
  scope :approved, -> { where(approval_status: "approved") }
  scope :rejected, -> { where(approval_status: "rejected") }
  scope :visible, -> { where(is_hidden: false) }
  scope :pending_for_specialist, -> { pending.where(requested_at: 30.days.ago..) }
  scope :doctor_prescribed, -> { where(source: "doctor_prescription") }

  before_validation :set_defaults, on: :create

  def pending?
    approval_status == "pending"
  end

  def approved?
    approval_status == "approved"
  end

  def rejected?
    approval_status == "rejected"
  end

  def hidden?
    is_hidden
  end

  def approve!(approver)
    update!(
      approval_status: "approved",
      approved_at: Time.current,
      approved_by_id: approver.id
    )
  end

  def reject!
    update!(approval_status: "rejected")
  end

  def hide!
    update!(is_hidden: true, hidden_at: Time.current)
  end

  def unhide!
    update!(is_hidden: false, hidden_at: nil)
  end

  def days_difference
    (Time.zone.today - start_date).to_i
  rescue TypeError
    raise :days_difference_errror
  end

  private

  def set_defaults
    self.approval_status ||= "pending"
    self.requested_at ||= Time.current if approval_status == "pending"
  end
end
