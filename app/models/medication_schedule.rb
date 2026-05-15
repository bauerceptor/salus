class MedicationSchedule < ApplicationRecord
  belongs_to :medication

  validates :scheduled_time, presence: true

  DAYS_OF_WEEK = {
    sunday: 0,
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6
  }.freeze

  TIMES_OF_DAY = {
    morning: 0,
    afternoon: 1,
    evening: 2,
    night: 3
  }.freeze

  scope :active, -> { where(is_active: true) }
  scope :upcoming, -> { active.where("scheduled_time > ?", Time.current) }
end
