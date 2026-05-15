FactoryBot.define do
  factory :ai_agent_message do
    association :conversation, factory: :ai_agent_conversation
    content { "Test message" }
    role { "user" }
  end
end
