FactoryBot.define do
  factory :specialist_request do
    association :account, factory: :account
    association :specialist, factory: :user
    field_of_expertise { "Cardiology" }
    specialization { "Heart Specialist" }
    specialization_description { "Board certified cardiologist with 10 years of experience" }
    message { "I would like to become a specialist" }
    status { "pending" }
    hash_code { SecureRandom.hex(6).upcase }
  end
end
