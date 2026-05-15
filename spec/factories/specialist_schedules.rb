FactoryBot.define do
  factory :specialist_schedule do
    association :specialist
    day_of_week { 1 }
    start_time { "09:00" }
    end_time { "09:30" }
    appointment_type { "MyString" }
    duration_minutes { 1 }
    is_active { false }
  end
end
