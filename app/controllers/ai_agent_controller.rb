class AiAgentController < BaseController
  def index
    @conversations = AiAgentConversation.where(account: current_account)
                                        .order(updated_at: :desc)
                                        .limit(20)
    @current_conversation = if params[:conversation_id].present?
                              AiAgentConversation.find(params[:conversation_id])
                            else
                              @conversations.first
                            end

    @messages = if @current_conversation
                  @current_conversation.messages.order(created_at: :asc)
                else
                  []
                end
  end

  def create_message
    conversation = if params[:conversation_id].present?
                     AiAgentConversation.find_or_create_by(
                       id: params[:conversation_id],
                       account: current_account
                     )
                   else
                     AiAgentConversation.create!(account: current_account, title: "New Chat")
                   end

    content = params[:content] || ""
    attachments = build_attachments(params)

    ai_message = conversation.messages.create!(
      role: "user",
      content: content,
      attachments: attachments
    )

    ai_service = AiAgentService.new(current_account)

    if content.start_with?("/adherence")
      ai_response = ai_service.analyze_medication_adherence
    elsif content.start_with?("/symptoms")
      ai_response = ai_service.analyze_symptom_trends
    elsif content.start_with?("/checkin")
      ai_response = generate_health_checkin(ai_service)
    else
      attachments.each do |att|
        ai_service.add_message("user", content, attachments: [att])
      end
      ai_service.add_message("user", content) if attachments.empty?
      Rails.logger.debug "[AiAgentController] Calling generate_response, configured: #{ai_service.configured?}"
      ai_response = ai_service.generate_response
      Rails.logger.debug "[AiAgentController] generate_response returned: #{ai_response.class} - #{ai_response&.slice(0, 100)}"
    end

    response_message = if ai_response.is_a?(String) && ai_response.present?
                         Rails.logger.debug "[AiAgentController] Creating assistant message with response"
                         conversation.messages.create!(
                           role: "assistant",
                           content: ai_response
                         )
                       else
                         Rails.logger.debug "[AiAgentController] Using fallback response"
                         fallback_response = generate_fallback_response(content, ai_service)
                         conversation.messages.create!(
                           role: "assistant",
                           content: fallback_response
                         )
                       end

    conversation.update!(updated_at: Time.current)

    render json: {
      user_message: render_message(ai_message),
      ai_response: render_message(response_message),
      conversation_id: conversation.id
    }
  end

  def generate_speech
    text = params[:text]
    return render json: { error: "No text provided" }, status: :bad_request if text.blank?

    ai_service = AiAgentService.new(current_account)
    audio_base64 = ai_service.generate_audio_response(text)

    if audio_base64
      render json: { audio: audio_base64, format: "mp3" }
    else
      render json: { error: "Failed to generate speech" }, status: :unprocessable_content
    end
  end

  def transcribe
    audio_data = params[:audio_data]
    format = params[:format] || "webm"

    return render json: { error: "No audio data provided" }, status: :bad_request if audio_data.blank?

    audio_data = audio_data.sub(/\Adata:audio\/[^;]+;base64,/, "")
    decoded_audio = Base64.decode64(audio_data)

    ai_service = AiAgentService.new(current_account)
    transcription = ai_service.transcribe_audio(decoded_audio, format)

    if transcription
      render json: { transcription: transcription }
    else
      render json: { error: "Transcription failed" }, status: :unprocessable_content
    end
  end

  def new_conversation
    conversation = AiAgentConversation.create!(
      account: current_account,
      title: "New Chat"
    )

    render json: { conversation_id: conversation.id }
  end

  def destroy_conversation
    conversation = AiAgentConversation.where(
      id: params[:id],
      account: current_account
    ).first

    if conversation&.destroy
      render json: { success: true }
    else
      render json: { error: "Conversation not found" }, status: :not_found
    end
  end

  private

  def build_attachments(params)
    attachments = []

    if params[:image_data].present?
      attachments << {
        type: "image",
        name: "image",
        data: params[:image_data]
      }
    end

    if params[:pdf_data].present?
      ai_service = AiAgentService.new(current_account)
      text = ai_service.extract_text_from_pdf(Base64.decode64(params[:pdf_data]))
      attachments << {
        type: "pdf",
        name: params[:pdf_name] || "document.pdf",
        data: text.truncate(10_000)
      }
    end

    if params[:voice_data].present?
      ai_service = AiAgentService.new(current_account)
      decoded_audio = Base64.decode64(params[:voice_data])
      transcription = ai_service.transcribe_audio(decoded_audio, params[:voice_format] || "webm")
      attachments << {
        type: "voice",
        name: "voice_message",
        data: nil,
        transcription: transcription || "Unable to transcribe"
      }
    end

    attachments
  end

  def generate_health_checkin(ai_service)
    summary = ["Hello! I'm checking in on your health. Here's a summary:"]

    medications = current_account.medications.active.limit(3)
    if medications.any?
      summary << "\n[Your Medications]"
      medications.each do |med|
        summary << "- #{med.name}: #{med.dosage}"
      end
    end

    last_measurement = current_account.measurements.order(measurement_date: :desc).first
    if last_measurement
      summary << "\n[Latest Measurement]"
      summary << "- #{last_measurement.measurement_type.name}: #{last_measurement.value} #{last_measurement.measurement_type.unit} (#{last_measurement.measurement_date.strftime('%b %d')})"
    end

    adherence = ai_service.analyze_medication_adherence
    summary << "\n#{adherence}"

    summary << "\nHow are you feeling today? Do you have any concerns I can help with?"

    summary.join("\n")
  end

  def generate_fallback_response(content, ai_service)
    if !ai_service.configured?
      "I'm not configured with an AI service yet. Please contact support to set up the AI integration. You can still use /adherence and /symptoms commands to view your health data."
    elsif content.blank? && params[:image_data].present?
      "I've received your image. Unfortunately, I can't analyze images without AI service configuration. Please contact support."
    elsif content.blank? && params[:pdf_data].present?
      "I've received your document. Unfortunately, I can't process PDFs without AI service configuration. Please contact support."
    else
      Rails.logger.warn "[AiAgentController] AI response was nil or empty. Check OpenAI API key configuration."
      "I'm having trouble connecting to the AI service right now. Please make sure the AI service is properly configured. You can still use /adherence and /symptoms commands to view your health data."
    end
  end

  def render_message(message)
    {
      id: message.id,
      role: message.role,
      content: message.content,
      attachments: message.attachments,
      created_at: message.created_at.strftime("%H:%M")
    }
  end
end
