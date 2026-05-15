FactoryBot.define do
  factory :health_agent_conversation do
    association :account
    persona { :patient }
    status { :active }
  end
end
