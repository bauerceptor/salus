FactoryBot.define do
  factory :specialist_recommendation do
    association :specialist, factory: :user
    association :account, factory: :account
    name { "Test Recommendation" }
    notes { "Recommendation notes" }
    recommendation_type { "medication" }
    status { "pending" }
  end
end
