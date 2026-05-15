# == Schema Information
#
# Table name: groups
#
#  id                    :uuid             not null, primary key
#  description           :string           default(""), not null
#  name                  :string           default(""), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  predefined_disease_id :uuid             not null
#  category              :integer          default: 0, not null
#
# Indexes
#
#  index_groups_on_predefined_disease_id  (predefined_disease_id)
#  index_groups_on_category               (category)
#
# Foreign Keys
#
#  fk_rails_...  (predefined_disease_id => predefined_diseases.id)
#
class Group < ApplicationRecord
  belongs_to :predefined_disease

  has_many :group_members, dependent: :destroy
  has_many :accounts, through: :group_members
  has_many :posts, dependent: :destroy, inverse_of: :group

  enum :category, { support: 0, informational: 1, advocacy: 2, general: 3 }, prefix: :category

  validates :name, allow_blank: true, length: { maximum: 50 }
  validates :description, allow_blank: true, length: { maximum: 100 }

  delegate :special?, to: :predefined_disease

  def accessible_to_all?
    special?
  end

  def specialist_member?(account)
    return false unless account.user&.specialist?

    account.user.specialist_patients.active.any? do |sp|
      sp.account.diseases.exists?(predefined_disease_id: predefined_disease_id)
    end
  end

  def self.accessible_by_specialist(specialist_user)
    return none unless specialist_user&.specialist?

    patient_disease_ids = specialist_user.specialist_patients.active
                                         .joins(:account)
                                         .where(accounts: { id: specialist_user.specialist_patients.pluck(:account_id) })
                                         .flat_map { |sp| sp.account.disease_ids }
                                         .uniq

    where(predefined_disease_id: patient_disease_ids)
  end
end
