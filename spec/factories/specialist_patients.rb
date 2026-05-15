FactoryBot.define do
  factory :specialist_patient do
    association :specialist, factory: :user
    association :account
    status { "active" }
  end
end
