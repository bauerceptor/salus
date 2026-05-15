FactoryBot.define do
  factory :treatment_request do
    association :account
    title { "Physical Therapy" }
    description { "Weekly sessions for rehabilitation" }
    start_date { Faker::Date.between(from: 3.days.ago, to: 3.days.from_now) }
    status { "pending" }
    requested_at { Time.current }

    trait :pending do
      status { "pending" }
    end

    trait :approved do
      status { "approved" }
      association :specialist, factory: :user
      reviewed_at { Time.current }
    end

    trait :rejected do
      status { "rejected" }
      association :specialist, factory: :user
      rejection_reason { "Not suitable for patient condition" }
      reviewed_at { Time.current }
    end
  end
end
