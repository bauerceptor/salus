# == Schema Information
#
# Table name: medications
#
#  id                             :uuid             not null, primary key
#  account_id                     :uuid             not null
#  disease_id                     :uuid
#  name                           :string           not null
#  dosage                         :string           not null
#  frequency                      :string           not null
#  instructions                   :text
#  start_date                     :date
#  end_date                       :date
#  is_active                      :boolean          default: true, not null
#  notes                          :text
#  reminder_enabled               :boolean          default: true, not null
#  reminder_minutes_before        :integer          default: 15
#  email_reminder_enabled         :boolean          default: false, not null
#  source                         :string
#  specialist_recommendation_id   :uuid
#  medication_request_id           :uuid
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#
# Indexes
#
#  index_medications_on_account_id                    (account_id)
#  index_medications_on_account_id_and_is_active      (account_id, is_active)
#  index_medications_on_source                        (source)
#  index_medications_on_specialist_recommendation_id  (specialist_recommendation_id)
#  index_medications_on_medication_request_id         (medication_request_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (disease_id => diseases.id)
#  fk_rails_...  (specialist_recommendation_id => specialist_recommendations.id)
#  fk_rails_...  (medication_request_id => medication_requests.id)
#
FactoryBot.define do
  factory :medication do
    account
    name { "Metformin" }
    dosage { "500mg" }
    frequency { "twice_daily" }
    is_active { true }

    trait :patient_request do
      source { "patient_request" }
      association :medication_request
      specialist_recommendation_id { nil }
    end

    trait :doctor_prescription do
      source { "doctor_prescription" }
      association :specialist_recommendation
      medication_request_id { nil }
    end
  end
end
