FactoryBot.define do
  factory :specialist_message do
    association :specialist, factory: :user
    association :account
    subject { "Test Subject" }
    body { "Test message body" }
    sender_type { "patient" }
  end
end
