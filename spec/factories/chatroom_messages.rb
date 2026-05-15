FactoryBot.define do
  factory :chatroom_message do
    chatroom
    account
    body { "Test message" }
  end
end