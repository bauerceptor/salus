class Caregiver < ApplicationRecord
  belongs_to :account
  belongs_to :caregiver_account, class_name: "Account"

  validates :relationship, presence: true
  validates :account_id, uniqueness: { scope: :caregiver_account_id }

  scope :accepted, -> { where(is_accepted: true) }
  scope :pending, -> { where(is_accepted: false) }
  scope :for_caregiver, ->(account) { where(caregiver_account_id: account.id) }
  scope :for_patient, ->(account) { where(account_id: account.id) }

  RELATIONSHIPS = {
    family: "family",
    friend: "friend",
    parent: "parent",
    spouse: "spouse",
    child: "child",
    sibling: "sibling",
    professional: "professional",
    other: "other"
  }.freeze

  def accept
    update(is_accepted: true)
  end

  def revoke
    update(is_accepted: false)
  end
end
