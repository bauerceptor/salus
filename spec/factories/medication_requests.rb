FactoryBot.define do
  factory :medication_request do
    association :account
    association :specialist, factory: :user
    medication_name { "Metformin" }
    dosage { "500mg" }
    frequency { "twice daily" }
    reason { "Type 2 diabetes management" }
    status { "pending" }
  end
end
