FactoryBot.define do
  factory :chatroom do
    association :account1, factory: :account
    association :account2, factory: :account
  end
end