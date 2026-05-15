class Notification < ApplicationRecord
  belongs_to :account
  belongs_to :notifiable, polymorphic: true, optional: true

  validates :title, presence: true
  validates :notification_type, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :for_account, ->(account) { where(account_id: account.id) }
  scope :recent, -> { order(created_at: :desc).limit(50) }

  def mark_as_read
    update(read_at: Time.current) if read_at.nil?
  end

  def unread?
    read_at.nil?
  end
end
