FactoryBot.define do
  factory :specialist_note do
    association :specialist, factory: :user
    association :account
    content { "Test note content" }
  end
end
