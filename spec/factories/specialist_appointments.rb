FactoryBot.define do
  factory :specialist_appointment do
    specialist { nil }
    patient { nil }
    schedule { nil }
    appointment_date { "2026-04-19" }
    start_time { "09:00" }
    end_time { "09:30" }
    status { "scheduled" }
    notes { "MyText" }
  end
end
