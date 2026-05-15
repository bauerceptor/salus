class MarkReadReceiptJob < ApplicationJob
  queue_as :default

  def perform(message_id, reader_id)
    message = ChatroomMessage.find(message_id)
    return if message.read_at.present?

    message.update!(read_at: Time.current)

    ChatroomChannel.broadcast_to(
      message.chatroom,
      {
        type: "read_receipt",
        message_id: message_id,
        read_at: message.read_at.iso8601,
        reader_id: reader_id
      }
    )
  end
end
