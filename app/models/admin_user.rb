# == Schema Information
#
# Table name: admins
#
#  id                  :uuid             not null, primary key
#  email               :string           default(""), not null
#  password_digest     :string           default(""), not null
#  remember_created_at :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_admins_on_email  (email) UNIQUE
#
class AdminUser < ApplicationRecord
  self.table_name = "admins"

  has_secure_password

  validates :email, presence: true, uniqueness: true
end
