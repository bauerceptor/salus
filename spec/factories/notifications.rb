FactoryBot.define do
  factory :notification do
    account
    title { "Test Notification" }
    body { "Notification body" }
    notification_type { "general" }
  end
end
