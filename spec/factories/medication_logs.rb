FactoryBot.define do
  factory :medication_log do
    association :medication_schedule, factory: :medication_schedule
    association :medication, factory: :medication
    account
    scheduled_for { Time.current }
    status { :pending }
  end
end
