# == Schema Information
#
# Table name: measurements
#
#  id                  :uuid             not null, primary key
#  is_within_limits    :boolean          default(TRUE), not null
#  measurement_date    :datetime         not null
#  value               :string           default("0.0"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :uuid             not null
#  measurement_type_id :uuid             not null
#
# Indexes
#
#  index_measurements_on_account_id           (account_id)
#  index_measurements_on_measurement_type_id  (measurement_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (measurement_type_id => measurement_types.id)
#
FactoryBot.define do
  factory :measurement do
    measurement_date { Time.current }
    value { rand(30..150) }
    association :measurement_type, factory: :weight_measurement_type
    association :account, factory: :account

    trait :weight do
      association :measurement_type, factory: :weight_measurement_type
      value { rand(30..150) }
    end

    trait :sugar do
      association :measurement_type, factory: :sugar_measurement_type
      value { rand(70..99) }
    end

    trait :heart_beat do
      association :measurement_type, factory: :heart_beat_measurement_type
      value { rand(60..100) }
    end

    trait :blood_pressure do
      association :measurement_type, factory: :blood_pressure_measurement_type
      value { "#{rand(110..130)}/#{rand(60..80)}" }
    end

    trait :spo2 do
      association :measurement_type, factory: :spo2_measurement_type
      value { rand(90..100) }
    end
  end
end
