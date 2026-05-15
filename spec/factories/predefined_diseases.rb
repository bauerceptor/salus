# == Schema Information
#
# Table name: predefined_diseases
#
#  id            :uuid             not null, primary key
#  description   :text             default(""), not null
#  icd10_code    :string           default(""), not null
#  name          :string           default(""), not null
#  related_names :string           default([]), is an Array
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  creates_group :boolean          default: true, not null
#
# Indexes
#
#  index_predefined_diseases_on_name  (name) UNIQUE
#
FactoryBot.define do
  factory :predefined_disease do
    name { Faker::Alphanumeric.alphanumeric(number: 32) }
    description { Faker::Lorem.paragraph }
    icd10_code { "A#{rand(10..99)}.#{rand(0..9)}" }
    creates_group { true }

    trait :liver_related do
      name { "hepatitis_b" }
      related_names { ["Hepatitis", "Cirrhosis", "Liver Cancer"] }
    end

    trait :no_group do
      creates_group { false }
    end
  end
end
