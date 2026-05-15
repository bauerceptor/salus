# == Schema Information
#
# Table name: medications
#
#  id                             :uuid             not null, primary key
#  account_id                     :uuid             not null
#  disease_id                     :uuid
#  name                           :string           not null
#  dosage                         :string           not null
#  frequency                      :string           not null
#  instructions                   :text
#  start_date                     :date
#  end_date                       :date
#  is_active                      :boolean          default: true, not null
#  notes                          :text
#  reminder_enabled               :boolean          default: true, not null
#  reminder_minutes_before        :integer          default: 15
#  email_reminder_enabled          :boolean          default: false, not null
#  source                         :string
#  specialist_recommendation_id   :uuid
#  medication_request_id          :uuid
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#
# Indexes
#
#  index_medications_on_account_id                    (account_id)
#  index_medications_on_account_id_and_is_active      (account_id, is_active)
#  index_medications_on_source                        (source)
#  index_medications_on_specialist_recommendation_id  (specialist_recommendation_id)
#  index_medications_on_medication_request_id         (medication_request_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (disease_id => diseases.id)
#  fk_rails_...  (specialist_recommendation_id => specialist_recommendations.id)
#  fk_rails_...  (medication_request_id => medication_requests.id)
#
class Medication < ApplicationRecord
  SOURCE_TYPES = %w[patient_request doctor_prescription].freeze

  belongs_to :account
  belongs_to :disease, optional: true
  belongs_to :specialist_recommendation, class_name: "SpecialistRecommendation", optional: true
  belongs_to :medication_request, optional: true

  has_many :medication_schedules, dependent: :destroy
  has_many :medication_logs, dependent: :destroy

  validates :name, presence: true
  validates :dosage, presence: true
  validates :frequency, presence: true
  validates :source, inclusion: { in: SOURCE_TYPES }, allow_nil: true
  validate :start_date_within_allowed_range, if: :start_date_present?
  validate :end_date_within_allowed_range, if: :end_date_present?
  validate :end_date_after_start_date, if: :both_dates_present?

  def start_date_present?
    start_date.present?
  end

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

  FREQUENCIES = {
    once_daily: 0,
    twice_daily: 1,
    three_times_daily: 2,
    four_times_daily: 3,
    as_needed: 4,
    weekly: 5,
    monthly: 6
  }.freeze

  scope :active, -> { where(is_active: true) }
  scope :for_account, ->(account) { where(account_id: account.id) }
  scope :with_reminders_enabled, -> { where(reminder_enabled: true) }
  scope :patient_request, -> { where(source: "patient_request") }
  scope :doctor_prescribed, -> { where(source: "doctor_prescription") }
end
