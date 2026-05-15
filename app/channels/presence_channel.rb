class PresenceChannel < ApplicationCable::Channel
  def subscribed
    current_account.update_presence(status: :online)
    stream_from "presence_channel"
  end

  def unsubscribed
    current_account.update_presence(status: :offline)
  end

  def typing(data)
    return unless current_account

    chatroom = Chatroom.find_by(id: data["chatroom_id"])
    current_account.update_presence(status: :online, chatroom: chatroom) if chatroom
  end
end
