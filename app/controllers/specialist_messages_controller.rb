class SpecialistMessagesController < BaseController
  before_action :set_message, only: [:show]
  before_action :set_conversation, only: [:show]
  before_action :mark_messages_read, only: [:show]
  before_action :set_assigned_doctor, only: [:index]
  before_action :verify_specialist_relationship!, only: [:create]

  def index
    return unless @assigned_doctor

    @specialist_user = @assigned_doctor.specialist
    @specialist_profile = @specialist_user.specialist
    @schedules = @specialist_profile&.specialist_schedules&.where(is_active: true)
    @appointments = SpecialistAppointment.where(patient: current_account).order(appointment_date: :desc).limit(10)
    return unless @specialist_user

    @conversation = SpecialistMessage.conversation(current_account.id, @specialist_user.id)
    @messages = @conversation.order(created_at: :asc) if @conversation.any?
    @new_message = SpecialistMessage.new(specialist_id: @specialist_user.id)
  end

  def show
    @message.mark_as_read! if @message.reply_from_specialist?
    @reply = SpecialistMessage.new(
      specialist_id: @message.specialist_id,
      account_id: current_account.id,
      parent_id: @message.id
    )
    @conversations = SpecialistMessage.where(account_id: current_account.id)
                                      .select(:specialist_id)
                                      .distinct
                                      .filter_map(&:specialist_id)
                                      .filter_map do |sid|
      SpecialistMessage.where(account_id: current_account.id,
                              specialist_id: sid).order(created_at: :desc).first
    end
  end

  def new
    @message = SpecialistMessage.new
    @specialist_id = params[:specialist_id]
  end

  def create
    @message = current_account.specialist_messages.build(message_params)
    @message.sender_type = "patient"

    if @message.save
      save_attachments(@message)
      @message.reload
      respond_to do |format|
        format.html { redirect_to patient_messages_path, notice: t(".success") }
        format.json do
          render json: {
            success: true,
            message: {
              id: @message.id,
              body: @message.body,
              created_at: @message.created_at.strftime("%H:%M"),
              attachments: @message.attachments.map { |a| { file_type: a.file_type, filename: a.filename, url: a.url, content_type: a.content_type } }
            }
          }
        end
      end
    else
      Rails.logger.error "Message save failed: #{@message.errors.full_messages}"
      respond_to do |format|
        format.html { redirect_to patient_messages_path, alert: @message.errors.full_messages.join(", ") }
        format.json { render json: { success: false, errors: @message.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_message
    @message = current_account.specialist_messages.find(params[:id])
  end

  def set_conversation
    @conversation = SpecialistMessage.conversation(current_account.id, @message.specialist_id)
  end

  def mark_messages_read
    @conversation.from_specialist.unread.where(account_id: current_account.id).update_all(is_read: true)
  end

  def set_assigned_doctor
    @assigned_doctor = current_account.specialist_patients.active.first
  end

  def verify_specialist_relationship!
    specialist_id = params.dig(:specialist_message, :specialist_id)
    return if specialist_id.blank?

    return if current_account.specialist_patients.active.exists?(specialist_id: specialist_id)

    redirect_to patient_messages_path, alert: "No active specialist relationship. Message not sent."
  end

  def message_params
    params.expect(specialist_message: %i[specialist_id subject body parent_id
                                         specialist_recommendation_id])
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
