FactoryBot.define do
  factory :breadcrumb do
    account
    title { "Test" }
    url { "/test" }
  end
end
