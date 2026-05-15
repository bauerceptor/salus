# == Schema Information
#
# Table name: specialist_patients
#
#  id                :uuid             not null, primary key
#  account_id        :uuid             not null, primary key
#  notes             :text
#  relationship_type :string           default("consulting"), not null
#  specialist_id     :uuid             not null, primary key
#  status            :string           default("pending"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_specialist_patients_on_specialist_id_and_account_id  (specialist_id,account_id) UNIQUE
#  index_specialist_patients_on_status                       (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (specialist_id => users.id)
#
class SpecialistPatient < ApplicationRecord
  belongs_to :specialist, class_name: "User"
  belongs_to :account

  validates :specialist_id, uniqueness: { scope: :account_id }

  STATUSES = %w[pending active inactive].freeze
  RELATIONSHIP_TYPES = %w[primary_care consulting specialist].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :relationship_type, inclusion: { in: RELATIONSHIP_TYPES }

  scope :active, -> { where(status: "active") }
  scope :pending, -> { where(status: "pending") }

  def approve!
    update!(status: "active")
  end

  def reject!
    update!(status: "inactive")
  end

  def active?
    status == "active"
  end

  def pending?
    status == "pending"
  end

  def inactive?
    status == "inactive"
  end
end
