class Specialist::MessagesController < Specialist::BaseController
  before_action :set_message, only: %i[show destroy]
  before_action :set_conversation, only: [:show]
  before_action :mark_messages_read, only: [:show]

  def index
    @conversations = current_user.specialist_messages
                                 .select("DISTINCT ON (account_id) *")
                                 .order(account_id: :asc, created_at: :desc)
  end

  def show
    @message.mark_as_read! if @message.reply_from_patient?
    @reply = SpecialistMessage.new(
      account_id: @message.account_id,
      specialist_id: current_user.id,
      parent_id: @message.id
    )
    @conversations = current_user.specialist_messages
                                 .select("DISTINCT ON (account_id) *")
                                 .order(account_id: :asc, created_at: :desc)
  end

  def new
    @message = SpecialistMessage.new
    @recipient_id = params[:recipient_id]
  end

  def create
    @message = current_user.specialist_messages.build(message_params)
    @message.sender_type = "specialist"

    if @message.save
      save_attachments(@message)
      @message.reload
      render json: {
        success: true,
        message: {
          id: @message.id,
          body: @message.body,
          created_at: @message.created_at.strftime("%H:%M"),
          attachments: @message.attachments.map { |a| { file_type: a.file_type, filename: a.filename, url: a.url, content_type: a.content_type } }
        }
      }
    else
      Rails.logger.error "Message save failed: #{@message.errors.full_messages}"
      render json: { success: false, errors: @message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @message.destroy
    redirect_to specialist_messages_path, notice: "Message deleted."
  end

  private

  def set_message
    @message = current_user.specialist_messages.find(params[:id])
  end

  def set_conversation
    @conversation = SpecialistMessage.conversation(@message.account_id, current_user.id)
  end

  def mark_messages_read
    @conversation.from_patient.unread.where(specialist_id: current_user.id).update_all(is_read: true)
  end

  def message_params
    params.expect(specialist_message: %i[account_id subject body parent_id specialist_recommendation_id])
  end

  def save_attachments(message)
    attachment = params[:attachment] || params[:attachments]
    return unless attachment

    attachments = attachment.is_a?(Array) ? attachment : [attachment]
    attachments.each do |att|
      next if att.blank?

      file_type = case att.content_type
                  when %r{\Aimage/}
                    "image"
                  when %r{\Avideo/}
                    "video"
                  when %r{\Aaudio/}
                    "voice"
                  else
                    "document"
                  end

      file_data = Base64.encode64(att.tempfile.read)

      message.attachments.create!(
        file_type: file_type,
        file_data: file_data,
        filename: att.original_filename,
        content_type: att.content_type
      )
    end
  end
end
