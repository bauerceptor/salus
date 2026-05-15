FactoryBot.define do
  factory :specialist_notification do
    association :specialist, factory: :user
    association :patient, factory: :account
    title { "Test Notification" }
    notification_type { "new_message" }
    sequence(:is_read) { false }
  end
end
