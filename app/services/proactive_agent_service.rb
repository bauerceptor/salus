class ProactiveAgentService
  OPENAI_URI = URI("https://api.openai.com/v1/chat/completions")
  MODEL = ENV.fetch("RUBY_LLM_MODEL", "gpt-4o")

  SYSTEM_INSTRUCTIONS = <<~TEXT.freeze
    You are Salus, a chronic care support companion. You are warm, encouraging, and clear.
    You help patients understand their health, medications, and care plans.
    You do not diagnose, prescribe, or provide specific treatment advice.
    If asked about model identity, say: "I am Salus, a custom improved model for chronic care support."
    If asked off-topic or irrelevant questions, respond: "I'm Salus, your chronic care support companion. I'm not designed to answer that type of question. How can I help you with your health today?"
    Always recommend consulting their specialist for medical decisions.
  TEXT

  def self.call(prompt:, system: nil, account: nil)
    new(account: account).generate(prompt: prompt, system: system)
  end

  def initialize(account:)
    @account = account
  end

  def generate(prompt:, system: nil)
    body = {
      model: MODEL,
      messages: messages_for(prompt, system: system),
      temperature: 0.7
    }

    request = Net::HTTP::Post.new(OPENAI_URI)
    request["Authorization"] = "Bearer #{ENV.fetch("OPENAI_API_KEY")}"
    request["Content-Type"] = "application/json"
    request.body = body.to_json

    response = Net::HTTP.start(OPENAI_URI.hostname, OPENAI_URI.port, use_ssl: true) do |http|
      http.request(request)
    end

    parsed = JSON.parse(response.body)

    if response.is_a?(Net::HTTPSuccess)
      parsed.dig("choices", 0, "message", "content")
    else
      Rails.logger.error("[ProactiveAgentService] OpenAI API error: #{parsed.inspect}")
      nil
    end
  rescue StandardError => e
    Rails.logger.error("[ProactiveAgentService] Error: #{e.message}")
    nil
  end

  private

  def messages_for(prompt, system: nil)
    system_content = [SYSTEM_INSTRUCTIONS]
    system_content << build_patient_context if @account.present?
    system_content << system if system.present?

    [
      { role: "system", content: system_content.compact.join("\n\n") },
      { role: "user", content: prompt }
    ]
  end

  def build_patient_context
    return nil if @account.blank?

    context_parts = []

    context_parts << "Patient name: #{@account.full_name}"

    if @account.medications.active.any?
      meds = @account.medications.active.select(:name, :dosage, :frequency).map do |m|
        "- #{m.name} (#{m.dosage}) - #{m.frequency.humanize}"
      end.join("\n")
      context_parts << "[Current Medications]\n#{meds}"
    end

    recent = @account.measurements.order(measurement_date: :desc).limit(5)
    if recent.any?
      measurements = recent.map do |m|
        "- #{m.measurement_type.name}: #{m.value} #{m.measurement_type.unit} (#{m.measurement_date.strftime('%b %d')})"
      end.join("\n")
      context_parts << "[Recent Measurements]\n#{measurements}"
    end

    context_parts.any? ? "\n\n[Patient Context]\n#{context_parts.join("\n\n")}" : nil
  end
end
