class Chatroom < ApplicationRecord
  belongs_to :account1, class_name: "Account"
  belongs_to :account2, class_name: "Account"
  has_many :chatroom_messages, dependent: :destroy
  has_many :chatroom_participants, dependent: :destroy

  validates :account1_id, uniqueness: { scope: :account2_id }

  def other_participant(current_account)
    account1 == current_account ? account2 : account1
  end

  def participants
    [account1, account2]
  end

  def last_message
    chatroom_messages.order(created_at: :desc).first
  end

  def unread_count(for_account)
    chatroom_messages.where("account_id != ? AND read_at IS NULL", for_account.id).count
  end
end