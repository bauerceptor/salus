FactoryBot.define do
  factory :health_observation_log do
    association :account
    association :specialist, factory: :user

    observation_type { "symptom_worsening" }
    confidence_level { 1 }
    evidence { ["Test evidence"] }
    triggered_by { "HealthAlertServiceSpec" }
    status { 0 }
    observation_count { 1 }
  end
end
