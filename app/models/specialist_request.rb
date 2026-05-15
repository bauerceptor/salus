# == Schema Information
#
# Table name: specialist_requests
#
#  account_id                      :uuid             not null
#  created_at                      :datetime         not null
#  field_of_expertise              :string
#  id                             :uuid             not null, primary key
#  message                        :text
#  specialization                  :string
#  specialization_description     :string
#  specialist_id                  :uuid             not null
#  status                         :string           default("pending"), not null
#  updated_at                      :datetime         not null
#
class SpecialistRequest < ApplicationRecord
  belongs_to :account
  belongs_to :specialist, class_name: "User"

  before_validation :set_default_status, on: :create

  STATES = %w[pending approved rejected].freeze

  validates :status, inclusion: { in: STATES }
  validates :field_of_expertise, presence: true, length: { maximum: 50 }
  validates :specialization, presence: true, length: { maximum: 50 }
  validates :specialization_description, presence: true, length: { maximum: 500 }

  def approve!
    return if status == "approved"

    ActiveRecord::Base.transaction do
      update!(status: "approved")
      unless Specialist.exists?(user_id: specialist_id)
        specialist = Specialist.create!(
          user_id: specialist_id,
          field_of_expertise: field_of_expertise,
          specialization: specialization,
          specialization_description: specialization_description
        )
        specialist.user&.add_role("specialist")
      end
      if account_id != specialist_id && !SpecialistPatient.exists?(account_id: account_id, specialist_id: specialist_id)
        SpecialistPatient.create!(
          account_id: account_id,
          specialist_id: specialist_id,
          status: "active",
          relationship_type: "primary_care"
        )
      end
    end
  end

  def reject!
    update!(status: "rejected")
  end

  def hash_code
    self[:hash_code] || id.split("-").first.upcase
  end

  private

  def set_default_status
    self.status ||= "pending"
  end
end
