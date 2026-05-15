# == Schema Information
#
# Table name: group_members
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :uuid
#  group_id   :uuid
#
# Indexes
#
#  index_group_members_on_account_id               (account_id)
#  index_group_members_on_group_id                 (group_id)
#  index_group_members_on_group_id_and_account_id  (group_id,account_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (group_id => groups.id)
#
class GroupMember < ApplicationRecord
  belongs_to :group
  belongs_to :account

  enum :role, { member: 0, moderator: 1, admin: 2 }, prefix: true

  validates :account_id, uniqueness: { scope: :group_id }

  after_create :set_creator_as_admin, if: :first_member?

  def specialist?
    return false unless account.user&.specialist?

    account.user.specialist_patients.active.any? do |sp|
      sp.account.diseases.exists?(predefined_disease_id: group.predefined_disease_id)
    end
  end

  private

  def first_member?
    GroupMember.where(group_id: group_id).one?
  end

  def set_creator_as_admin
    update!(role: :admin) if role_member?
  end
end
