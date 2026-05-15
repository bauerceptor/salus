class EmergencyContact < ApplicationRecord
  belongs_to :account

  validates :name, presence: true
  validates :phone_number, presence: true
  validates :relationship, presence: true

  scope :notifyable, -> { where(notify_on_emergency: true) }
  scope :for_account, ->(account) { where(account_id: account.id) }
end
