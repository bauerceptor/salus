FactoryBot.define do
  factory :caregiver do
    association :account
    association :caregiver_account, factory: :account
    relationship { "family" }
    is_accepted { false }
  end
end
