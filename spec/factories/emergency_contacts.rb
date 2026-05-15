FactoryBot.define do
  factory :emergency_contact do
    account
    name { "Emergency Contact" }
    phone_number { "1234567890" }
    relationship { "family" }
    is_primary { false }
  end
end
