class ChatroomParticipant < ApplicationRecord
  belongs_to :account
  belongs_to :chatroom

  validates :account_id, uniqueness: { scope: :chatroom_id }
end