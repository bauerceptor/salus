# == Schema Information
#
# Table name: specialist_recommendations
#
#  id                   :uuid             not null, primary key
#  account_id           :uuid             not null, primary key
#  dosage               :string
#  medication_id        :uuid
#  name                 :string           not null
#  notes                :text
#  recommendation_type  :string           not null
#  specialist_id        :uuid             not null, primary key
#  status               :string           default("pending"), not null
#  treatment_id         :uuid
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_specialist_recommendations_on_specialist_id_and_account_id  (specialist_id,account_id)
#  index_specialist_recommendations_on_status                       (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (medication_id => medications.id)
#  fk_rails_...  (specialist_id => users.id)
#  fk_rails_...  (treatment_id => treatments.id)
#
class SpecialistRecommendation < ApplicationRecord
  belongs_to :specialist, class_name: "User"
  belongs_to :account
  belongs_to :medication, optional: true
  belongs_to :treatment, optional: true

  RECOMMENDATION_TYPES = %w[medication treatment].freeze
  STATUSES = %w[pending accepted rejected dismissed].freeze

  validates :recommendation_type, inclusion: { in: RECOMMENDATION_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :name, presence: true, length: { maximum: 255 }

  after_create :notify_patient
  after_update :notify_status_change, if: :saved_change_to_status?

  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }
  scope :for_patient, ->(account) { where(account_id: account.id) }

  def accept!
    ActiveRecord::Base.transaction do
      update!(status: "accepted")
      create_treatment_from_recommendation if treatment?
      create_medication_from_recommendation if medication?
    end
  end

  def reject!
    update!(status: "rejected")
  end

  def dismiss!
    update!(status: "dismissed")
  end

  def pending?
    status == "pending"
  end

  def medication?
    recommendation_type == "medication"
  end

  def treatment?
    recommendation_type == "treatment"
  end

  private

  def notify_patient
    AlertNotificationJob.perform_later(
      "recommendation",
      account_id,
      {
        notifiable: self,
        specialist_id: specialist_id,
        recommendation_type: recommendation_type,
        name: name,
        message: "Dr. #{specialist.account.full_name} recommended #{name}"
      }
    )
  end

  def notify_status_change
    return unless saved_change_to_status? && status == "accepted"

    Notification.create!(
      account: account,
      title: "Recommendation Accepted",
      body: "Your medication #{name} has been added to your list.",
      notification_type: "recommendation_accepted",
      notifiable: self
    )
  end

  def create_treatment_from_recommendation
    Treatment.create!(
      account: account,
      title: name,
      description: notes.presence || "Doctor's recommendation",
      source: "doctor_prescription",
      specialist_recommendation_id: id,
      approval_status: "approved",
      approved_at: Time.current,
      approved_by_id: specialist_id,
      start_date: Date.current,
      effectiveness: 3
    )
  end

  def create_medication_from_recommendation
    Medication.create!(
      account: account,
      name: name,
      dosage: dosage || "Not specified",
      frequency: "As prescribed",
      is_active: true,
      source: "doctor_prescription",
      specialist_recommendation_id: id
    )
  end
end
