class SpecialistAppointment < ApplicationRecord
  belongs_to :specialist, class_name: "Specialist"
  belongs_to :patient, class_name: "Account"
  belongs_to :schedule, class_name: "SpecialistSchedule"

  enum :status, { scheduled: "scheduled", confirmed: "confirmed", completed: "completed", cancelled: "cancelled" }
end
