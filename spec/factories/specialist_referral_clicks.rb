FactoryBot.define do
  factory :specialist_referral_click do
    association :specialist_request
    ip_address { Faker::Internet.ip_v4_address }
    user_agent do
      ["Mozilla/5.0 (Windows NT 10.0; Win64; x64)", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
       "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)"].sample
    end
    clicked_at { Time.current }
  end
end
