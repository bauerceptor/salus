FactoryBot.define do
  factory :emergency_alert do
    account
    alert_type { "high_risk" }
    status { "active" }
  end
end
