module HealthAgent
  class ChatController < HealthAgent::BaseController
    before_action :set_conversation

    def index
      @messages = @conversation.messages.order(created_at: :asc)
    end

    def create
      content = message_params[:content]
      return render json: { error: "Content required" }, status: :unprocessable_content if content.blank?

      message = @conversation.messages.new(
        role: :user,
        content: content
      )
      message.attachment.attach(message_params[:attachment]) if message_params[:attachment]

      return render json: { errors: message.errors.full_messages }, status: :unprocessable_content unless message.save

      service = HealthAgentService.new(
        account: current_account,
        specialist: current_specialist
      )

      response = service.ask(
        message.content,
        persona: @conversation.persona_patient? ? :patient : :specialist
      )

      assistant_msg = @conversation.messages.create!(
        role: :assistant,
        content: response
      )

      render json: {
        user_message: render_message(message),
        ai_response: render_message(assistant_msg),
        conversation_id: @conversation.id
      }
    end

    private

    def set_conversation
      @conversation = HealthAgentConversation.find_or_create_by!(
        account: current_account,
        persona: conversation_persona
      )
    end

    def conversation_persona
      persona = params[:persona].presence || "patient"
      persona.to_sym == :specialist ? :specialist : :patient
    end

    def message_params
      params.permit(:content, :attachment)
    end

    def render_message(message)
      data = {
        id: message.id,
        role: message.role.to_s,
        content: message.content,
        created_at: message.created_at.strftime("%H:%M")
      }

      if message.attachment.attached?
        data[:attachment_url] = url_for(message.attachment)
        data[:attachment_content_type] = message.attachment.content_type
        data[:attachment_filename] = message.attachment.filename.to_s
      end

      data
    end

    def current_specialist
      return nil unless current_user&.specialist

      current_user.specialist
    end
  end
end
