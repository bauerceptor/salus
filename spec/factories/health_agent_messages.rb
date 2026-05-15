FactoryBot.define do
  factory :health_agent_message do
    association :conversation, factory: :health_agent_conversation
    role { :user }
    content { "Test message content" }
    attachments { [] }
  end
end
