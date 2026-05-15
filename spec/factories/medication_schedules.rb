FactoryBot.define do
  factory :medication_schedule do
    medication
    scheduled_time { "08:00" }
    day_of_week { "monday" }
    is_active { true }
  end
end
