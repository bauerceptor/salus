class ChatroomMessageBroadcastJob < ApplicationJob
  queue_as :default

  def perform(message)
    ChatroomChannel.broadcast_to(
      message.chatroom,
      {
        type: "message",
        message: {
          id: message.id,
          body: message.body,
          message_type: message.message_type,
          account_id: message.account.id,
          username: message.account.username,
          avatar_url: message.account.image.attached? ? url_for(message.account.image) : nil,
          created_at: message.created_at.iso8601,
          attachment_url: message.attachment&.attached? ? url_for(message.attachment) : nil,
          attachment_content_type: message.attachment&.content_type
        }
      }
    )
  end
end