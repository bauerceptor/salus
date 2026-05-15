# == Schema Information
#
# Table name: treatments
#
#  id                             :uuid             not null, primary key
#  account_id                      :uuid             not null
#  approval_status                 :string           default: "pending", not null
#  approved_at                     :datetime
#  approved_by_id                  :uuid
#  description                     :text             default: "", not null
#  effectiveness                   :integer          default: 0, not null
#  end_date                        :date
#  hidden_at                       :datetime
#  is_finished                     :boolean          default: FALSE, not null
#  is_hidden                       :boolean          default: FALSE, not null
#  name                            :string           default: "", not null
#  requested_at                    :datetime
#  source                          :string
#  specialist_recommendation_id    :uuid
#  start_date                      :date
#  status                          :string           default: "active"
#  title                           :string           default: "", not null
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#
# Indexes
#
#  index_treatments_on_account_id                          (account_id)
#  index_treatments_on_source                              (source)
#  index_treatments_on_specialist_recommendation_id        (specialist_recommendation_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
FactoryBot.define do
  factory :treatment do
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph(sentence_count: 2) }
    start_date { Faker::Date.between(from: 3.days.ago, to: 3.days.from_now) }
    effectiveness { rand(1..5) }
    account
    approval_status { "approved" }

    trait :patient_request do
      source { "patient_request" }
      specialist_recommendation_id { nil }
    end

    trait :doctor_prescription do
      source { "doctor_prescription" }
      association :specialist_recommendation
    end
  end
end
