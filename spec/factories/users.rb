# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  consumed_timestep      :integer
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  failed_attempts        :integer          default(0), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  locked_at              :datetime
#  otp_backup_codes       :string           is an Array
#  otp_required_for_login :boolean          default(FALSE), not null
#  otp_secret             :string
#  provider               :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  uid                    :string
#  unconfirmed_email      :string
#  unlock_token           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { "password" }
    tos_agreement { true }
    after(:create) { |user| create(:account, user: user) unless user.account }

    trait :specialist do
      after(:create) do |user, _|
        Role.find_or_create_by!(name: "specialist")
        user.add_role("specialist")
        unless user.specialist
          specialist = Specialist.new(
            specialization: "Cardiology",
            field_of_expertise: "Heart Specialist",
            specialization_description: "General cardiology practice"
          )
          specialist.user = user
          specialist.save!
        end
      end
    end

    trait :two_factor_enabled do
      after(:create) do |user, _|
        user.enable_two_factor!
      end
    end
  end
end
