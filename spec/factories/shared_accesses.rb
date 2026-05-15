FactoryBot.define do
  factory :shared_access do
    association :account, factory: :account
    association :shared_with_account, factory: :account
    association :shareable, factory: :disease
  end
end
