class ChatroomMessagesController < BaseController
  before_action :set_chatroom

  def create
    @message = @chatroom.chatroom_messages.new(message_params)
    @message.account = current_account

    if params[:attachment]
      @message.attachment.attach(params[:attachment])
    end

    if @message.save
      @chatroom.touch

      broadcast_data = {
        type: "message",
        id: @message.id,
        body: @message.body,
        account_id: @message.account.id,
        username: @message.account.username,
        avatar_url: @message.account.image&.attached? ? url_for(@message.account.image) : nil,
        created_at: @message.created_at.strftime("%H:%M"),
        attachment_url: @message.attachment&.attached? ? url_for(@message.attachment) : nil,
        attachment_content_type: @message.attachment&.content_type,
        attachment_filename: @message.attachment&.filename&.to_s,
        message_type: @message.message_type.to_s
      }

      ActionCable.server.broadcast("chatroom_#{@chatroom.id}", broadcast_data)
      render json: { success: true, message: broadcast_data }
    else
      render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_chatroom
    @chatroom = Chatroom.where("account1_id = ? OR account2_id = ?", current_account.id, current_account.id).find(params[:chatroom_id])
  end

  def message_params
    params.require(:chatroom_message).permit(:body, :message_type).merge(account: current_account)
  end
end