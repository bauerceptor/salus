class AiAgentService
  OPENAI_URL = "https://api.openai.com/v1/chat/completions".freeze

  def initialize(account = nil)
    @account = account
    @messages = []
    @inject_context = true
  end

  def add_message(role, content, attachments: [])
    message = { role: role, content: content }
    message[:content] = build_multimodal_content(content, attachments) if attachments.any?
    @messages << message
  end

  def build_multimodal_content(content, attachments)
    blocks = []
    blocks << { type: "text", text: content } if content.present?
    attachments.each do |attachment|
      case attachment["type"]
      when "image"
        image_data = attachment["data"] || attachment["image_data"]
        if image_data.present?
          if image_data.starts_with?("data:image")
            blocks << { type: "image_url", image_url: { url: image_data } }
          else
            mime_type = attachment["mime_type"] || "image/jpeg"
            blocks << { type: "image_url", image_url: { url: "data:#{mime_type};base64,#{image_data}" } }
          end
        end
      when "pdf"
        text = attachment["extracted_text"] || attachment["data"] || ""
        blocks << { type: "text", text: "PDF document: #{attachment['name']}\n#{text}" }
      when "voice"
        blocks << { type: "text", text: "Voice message transcription: #{attachment['transcription'] || 'Unable to transcribe'}" }
      end
    end
    blocks
  end

  def build_system_context
    return nil if @account.blank?

    context = []
    context << build_patient_summary
    context << build_medication_context if @account.medications.any?
    context << build_recent_measurements if @account.measurements.any?
    context << build_active_diseases if @account.diseases.any?

    context.compact.join("\n\n")
  end

  def build_patient_summary
    <<~TEXT
      [PATIENT PROFILE]
      Name: #{@account.full_name}
      Age: #{@account.birthday ? ((Time.zone.today - @account.birthday) / 365).floor : 'Unknown'}
      Location: #{@account.city.presence || 'Unknown'}, #{@account.country.presence || 'Unknown'}
    TEXT
  end

  def build_medication_context
    meds = @account.medications.active.select(:name, :dosage, :frequency).map do |m|
      "- #{m.name} (#{m.dosage}) - #{m.frequency.humanize}"
    end.join("\n")

    <<~TEXT
      [CURRENT MEDICATIONS]
      #{meds}
    TEXT
  end

  def build_recent_measurements
    recent = @account.measurements.order(measurement_date: :desc).limit(5)
    measurements = recent.map do |m|
      "- #{m.measurement_type.name}: #{m.value} #{m.measurement_type.unit} (#{m.measurement_date.strftime('%b %d')})"
    end.join("\n")

    <<~TEXT
      [RECENT MEASUREMENTS]
      #{measurements}
    TEXT
  end

  def build_active_diseases
    diseases = @account.diseases
                       .map { |d| "- #{d.predefined_disease.name} (#{d.severity || 'unspecified'})" }
                       .join("\n")

    <<~TEXT
      [DIAGNOSED CONDITIONS]
      #{diseases}
    TEXT
  end

  def analyze_medication_adherence
    return nil if @account.blank?

    logs = @account.medication_logs.where(scheduled_for: 30.days.ago..)
                   .order(scheduled_for: :desc)

    return "No medication history found." if logs.empty?

    total = logs.count
    taken = logs.taken.count
    missed = logs.missed.count
    skipped = logs.skipped.count
    adherence_rate = total.positive? ? ((taken.to_f / total) * 100).round(1) : 0

    summary = []
    summary << "Medication Adherence Report (Last 30 Days):"
    summary << "- Overall Adherence Rate: #{adherence_rate}%"
    summary << "- Total Scheduled: #{total}"
    summary << "- Taken: #{taken} (#{total.positive? ? ((taken.to_f / total) * 100).round(1) : 0}%)"
    summary << "- Missed: #{missed} (#{total.positive? ? ((missed.to_f / total) * 100).round(1) : 0}%)"
    summary << "- Skipped: #{skipped} (#{total.positive? ? ((skipped.to_f / total) * 100).round(1) : 0}%)"

    if adherence_rate < 70
      summary << "\n⚠️ WARNING: Your adherence rate is below 70%. Consider setting up reminders or discussing with your doctor."
    elsif adherence_rate >= 90
      summary << "\n✓ Great job maintaining a #{adherence_rate}% adherence rate!"
    end

    summary.join("\n")
  end

  def analyze_symptom_trends
    return nil if @account.blank?

    symptoms = @account.disease_symptom_updates
                       .where(created_at: 30.days.ago..)
                       .order(created_at: :desc)
                       .limit(20)

    return "No symptom data found." if symptoms.empty?

    grouped = symptoms.group_by { |s| s.disease_symptom.name }
    trends = []

    grouped.each do |symptom_name, updates|
      intensities = updates.map(&:intensity)
      avg_intensity = (intensities.sum.to_f / intensities.length).round(1)
      max_intensity = intensities.max
      min_intensity = intensities.min

      trend = if max_intensity - min_intensity > 2
                avg_intensity > 3 ? "worsening ↑" : "improving ↓"
              else
                "stable →"
              end

      trends << "- #{symptom_name}: avg #{avg_intensity}/5 (#{trend})"
    end

    summary = ["Symptom Trends Report (Last 30 Days):"]
    summary << trends.join("\n")
    summary << "\nNote: This is an automated analysis. Always consult your doctor for medical decisions."

    summary.join("\n")
  end

  def configured?
    api_key.present?
  end

  def generate_response
    return nil unless configured?

    inject_system_context if @inject_context && @account.present?

    Rails.logger.debug "[AiAgentService] Sending request with #{@messages.size} messages"
    Rails.logger.debug "[AiAgentService] API Key present: #{api_key.present?}"

    payload = {
      model: "gpt-4o",
      messages: @messages,
      max_tokens: 4096,
      temperature: 0.7,
      stream: false
    }

    uri = URI.parse(OPENAI_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 60

    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = payload.to_json

    response = http.request(request)
    Rails.logger.debug "[AiAgentService] Response code: #{response.code}"

    if response.code == "200"
      result = JSON.parse(response.body)
      content = result.dig("choices", 0, "message", "content")
      Rails.logger.debug "[AiAgentService] Received content length: #{content&.length || 0}"
      content
    else
      Rails.logger.warn "[AiAgentService] API Error: #{response.body}"
      { error: "AI service error", details: response.body }.to_s
    end
  end

  def generate_audio_response(text)
    return nil if api_key.nil?

    uri = URI.parse("https://api.openai.com/v1/audio/speech")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    payload = {
      model: "tts-1",
      input: text,
      voice: "alloy",
      response_format: "mp3"
    }

    request = Net::HTTP::Post.new(uri.request_uri, audio_headers)
    request.body = payload.to_json

    response = http.request(request)

    return unless response.code == "200"

    Base64.encode64(response.body)
  end

  def transcribe_audio(audio_data, format = "webm")
    return nil if api_key.nil?

    Rails.logger.debug "[AiAgentService] transcribe_audio called with data length: #{audio_data.length}, format: #{format}"

    begin
      require "net/http/post/multipart"

      io = StringIO.new(audio_data)
      io.binmode

      uri = URI.parse("https://api.openai.com/v1/audio/transcriptions")
      req = Net::HTTP::Post::Multipart.new(
        uri.path,
        {
          "model" => "whisper-1",
          "file" => UploadIO.new(io, "audio/webm", "audio.webm")
        },
        "Authorization" => "Bearer #{api_key}"
      )

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 60

      response = http.request(req)
      Rails.logger.debug "[AiAgentService] Transcription response code: #{response.code}"
      Rails.logger.debug "[AiAgentService] Transcription response body: #{response.body[0..500]}"

      return unless response.code == "200"

      result = JSON.parse(response.body)
      result["text"]
    rescue => e
      Rails.logger.error "[AiAgentService] Transcription request failed: #{e.class} - #{e.message}"
      Rails.logger.error "[AiAgentService] Backtrace: #{e.backtrace[0..5].join("\n")}"
      nil
    end
  end

  def extract_text_from_pdf(pdf_data)
    reader = PDF::Reader.new(StringIO.new(pdf_data))
    text = ""
    reader.pages.each do |page|
      text += "#{page.text}\n"
    end
    text
  rescue StandardError => e
    "Unable to extract text from PDF: #{e.message}"
  end

  private

  def inject_system_context
    system_context = build_system_context
    return unless system_context

    @messages.unshift({
                        role: "system",
                        content: "You are an AI Health Assistant called Salus. You have access to the patient's health information provided below. Use this context to provide personalized health advice, but always remind patients to consult their healthcare providers for medical decisions.\n\n#{system_context}"
                      })
  end

  def api_key
    ENV.fetch("OPENAI_API_KEY", nil)
  end

  def headers
    {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{api_key}"
    }
  end

  def audio_headers
    {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{api_key}"
    }
  end
end
