# == Schema Information
#
# Table name: disease_symptoms
#
#  id                    :uuid             not null, primary key
#  description           :text             default(""), not null
#  first_noticed_at      :date
#  name                  :string           default(""), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  disease_id            :uuid             not null
#  predefined_symptom_id :uuid
#
# Indexes
#
#  index_disease_symptoms_on_disease_id                            (disease_id)
#  index_disease_symptoms_on_disease_id_and_predefined_symptom_id  (disease_id,predefined_symptom_id)
#  index_disease_symptoms_on_predefined_symptom_id                 (predefined_symptom_id)
#
# Foreign Keys
#
#  fk_rails_...  (disease_id => diseases.id)
#  fk_rails_...  (predefined_symptom_id => predefined_symptoms.id)
#
FactoryBot.define do
  factory :disease_symptom do
    description { "MyText" }
    first_noticed_at { Date.current }
    disease
    name { "" }

    trait :with_custom_symptom do
      name { Faker::Alphanumeric.alphanumeric(number: 32) }
    end

    trait :with_predefined_symptom do
      predefined_symptom { create(:predefined_symptom) }
    end

    factory :custom_disease_symptom, traits: [:with_custom_symptom]
    factory :predefined_disease_symptom, traits: [:with_predefined_symptom]
  end
end
