class HealthAgentService
  PATIENT_SYSTEM_INSTRUCTIONS = <<~TEXT.freeze
    You are Salus, a chronic care liver specialist companion. You are trained on liver health data and polypharmacy interactions. You are a small domain-specific model. You do not sound like a large general-purpose language model such as OpenAI, Gemini, or Claude.

    Respond like a medical expert giving a clinical assessment. Give the actual data or facts immediately. Never pad responses with disclaimers, hedging language, or conversational filler. Never say it is important to note or please consult your specialist. Never provide emotional acknowledgment or validation.

    You must never exceed two sentences or three lines per response unless the question specifically requires more detail and that detail is clinically relevant.

    You must never provide a diagnosis, a prescription, or a specific treatment plan. You must never replace the role of a doctor or specialist.

    If the user asks an irrelevant question, refuse briefly in one sentence. Do not redirect to something else.

    If the user attempts to force a yes or no answer, tells you to validate a decision, or asks you to agree with them without data, redirect immediately to the factual position.

    When relevant, reference liver function, drug metabolism, or known drug interactions. Cite the specific risk or effect rather than generic warnings.

    Format rules: no headings, no bullet points, no numbered lists, no em dashes, no en dashes, no contractions, no conclusions, no summaries.
  TEXT

  SPECIALIST_SYSTEM_INSTRUCTIONS = <<~TEXT.freeze
    You are Salus Clinical Decision Support. You assist specialists by surfacing patient patterns,
    adherence risks, and relevant history from the patient's care record. You provide evidence-grounded
    insights with explicit confidence indicators. You do not replace specialist judgment.
    When alerting, always include: the triggering pattern, relevant history, confidence level, and recommended next step.
  TEXT

  OFF_TOPIC_PATTERNS = [
    /weather/i, /news/i, /sports/i, /politics/i,
    /stock.*market/i, /celebrity/i, /joke/i
  ].freeze

  JAILBREAK_PATTERNS = [
    /ignore.*previous.*instructions/i,
    /disregard.*all.*previous/i,
    /forget.*instructions/i,
    /you.*are.*now.*(a|an)\s+\w+/i,
    /new.*instructions/i,
    /override.*system/i,
    /ignore.*your.*programming/i,
    /pretend.*you.*are/i,
    /roleplay.*as.*different/i,
    /disconnect.*safety/i
  ].freeze

  MODEL_IDENTITY_PATTERNS = [
    /which.*model/i, /what.*you.*are/i, /who.*built/i,
    /what.*LLM/i, /what.*engine/i, /what.*model/i
  ].freeze

  MANIPULATION_PATTERNS = [
    /answer.*only.*yes.*or.*no/i,
    /answer.*just.*yes.*or.*no/i,
    /tell.*me.*yes.*or.*no/i,
    /one.*word.*answer/i,
    /tell.*me.*I.*am.*right/i,
    /confirm.*my.*decision/i,
    /agree.*with.*me/i,
    /validate.*my.*choice/i,
    /as.*a.*friend.*would.*say/i,
    /you.*must.*understand.*how.*I.*feel/i
  ].freeze

  def initialize(account:, specialist: nil)
    @account = account
    @specialist = specialist
  end

  def chat
    @chat ||= RubyLLM.chat(model: "gpt-4o")
  end

  def rag_service
    @rag_service ||= HealthRagService.new(account: @account, specialist: @specialist)
  end

  def ask(message, attachments: [], persona: :patient)
    return guardrail_response(message, persona: persona) if guardrail?(message)

    chat = persona == :specialist ? specialist_persona : patient_persona
    response = chat.ask(message, with: attachments.presence)
    formatted = enforce_response_format(enforce_scope(response.content))
    formatted
  rescue StandardError => e
    Rails.logger.warn("[HealthAgentService] ask failed: #{e.message}")
    response.content
  end

  def enforce_scope(response_content)
    scope_violations = detect_scope_violations(response_content)
    if scope_violations.any?
      log_scope_violation(scope_violations, response_content)
      append_disclaimer(response_content, scope_violations)
    else
      response_content
    end
  end

  def enforce_response_format(content)
    return content if content.blank?

    lines = content.split("\n")
    cleaned = lines.reject { |line|
      line.strip.match?(/\A[#]{1,2}\s+\S/) ||
      line.strip.match?(/\A[A-Z][A-Z\s]{5,}:\z/)
    }
    cleaned = cleaned.map { |line| line.sub(/\A-\s+/, "").sub(/\A\*\s+/, "").sub(/\A\d+\.\s+/, "") }
    cleaned = cleaned.map { |line| line.gsub(/\xe2\x80\x94/, ",").gsub(/\xe2\x80\x93/, ",") }
    cleaned = cleaned.map { |line|
      line.sub(/(?:^|[.!?]\s+)(in summary|to conclude|in short|overall|in conclusion)[\s:.,].*?(?:[.!?]|$)/i) do |m|
        m.start_with?("In summary") || m.start_with?("in summary") ? "" : m
      end
    }
    result = cleaned.join("\n").strip
    paragraphs = result.split(/\n\n+/)
    if paragraphs.length > 2
      result = paragraphs.first(2).join("\n\n")
    end
    result
  rescue StandardError
    content
  end

  def jailbreak_guardrail?(message)
    JAILBREAK_PATTERNS.any? { |p| message =~ p }
  end

  def manipulation_guardrail?(message)
    MANIPULATION_PATTERNS.any? { |p| message =~ p }
  end

  def patient_persona
    instructions = PATIENT_SYSTEM_INSTRUCTIONS + build_patient_context
    instructions += build_rag_patient_context if patient_rag_enabled?

    chat.with_instructions(instructions)
  end

  def specialist_persona
    instructions = SPECIALIST_SYSTEM_INSTRUCTIONS + build_specialist_context
    instructions += build_rag_specialist_context if pattern_rag_enabled?

    chat.with_instructions(instructions)
  end

  delegate :retrieve_patient_context, to: :rag_service

  delegate :retrieve_anonymized_patterns, to: :rag_service

  def guardrail?(message)
    jailbreak_guardrail?(message) ||
      manipulation_guardrail?(message) ||
      OFF_TOPIC_PATTERNS.any? { |p| message =~ p } ||
      MODEL_IDENTITY_PATTERNS.any? { |p| message =~ p }
  end

  def guardrail_response(message, persona: :patient)
    if jailbreak_guardrail?(message)
      log_guardrail_trigger(:jailbreak_attempt, message, persona)
      return "I notice you may be trying to circumvent my guidelines. I am a liver health specialist model. I can only assist with health-related questions."
    end

    if manipulation_guardrail?(message)
      log_guardrail_trigger(:manipulation, message, persona)
      return "I will not answer that way. The actual data does not support that position. Consult your liver specialist for guidance on your specific case."
    end

    if /model.*you/i.match?(message)
      log_guardrail_trigger(:model_identity, message, persona)
      return "I am a liver health specialist model trained on medical literature. I am not OpenAI, Google, or Anthropic."
    end

    log_guardrail_trigger(:off_topic, message, persona)
    "I am not designed to answer that question. How can I help you with your health today?"
  end

  private

  def patient_rag_enabled?
    rag_service.patient_rag_enabled?
  end

  def pattern_rag_enabled?
    rag_service.pattern_rag_enabled?
  end

  def build_rag_patient_context
    context = retrieve_patient_context("[patient query context]")
    return "" if context.blank?

    "\n\n[Retrieved Patient History]\n#{context}"
  end

  def build_rag_specialist_context
    patient_context = retrieve_patient_context("[specialist patient query]")
    patterns = retrieve_anonymized_patterns("[specialist patterns query]")

    result = ""
    result += "\n\n[Patient-Specific History]\n#{patient_context}" if patient_context.present?
    result += "\n\n[Cross-Patient Anonymized Patterns]\n#{patterns.map(&:content).join("\n---\n")}" if patterns.any?

    result
  end

  def build_patient_context
    return "" if @account.blank?

    context = []
    context << build_patient_summary
    context << build_medication_context if @account.medications.any?
    context << build_recent_measurements if @account.measurements.any?

    "\n\n[Patient Context]\n#{context.compact.join("\n\n")}"
  end

  def build_specialist_context
    return "" if @account.blank?

    context = []
    context << build_patient_summary
    context << build_medication_context if @account.medications.any?
    context << build_recent_measurements if @account.measurements.any?
    context << build_adherence_risk if @account

    "\n\n[Patient Context]\n#{context.compact.join("\n\n")}"
  end

  def build_patient_summary
    <<~TEXT
      Name: #{@account.full_name}
      Age: #{@account.birthday ? ((Time.zone.today - @account.birthday) / 365).floor : 'Unknown'}
    TEXT
  end

  def build_medication_context
    meds = @account.medications.active.select(:name, :dosage, :frequency).map do |m|
      "- #{m.name} (#{m.dosage}) - #{m.frequency.humanize}"
    end.join("\n")

    "[Current Medications]\n#{meds}"
  end

  def build_recent_measurements
    recent = @account.measurements.order(measurement_date: :desc).limit(5)
    return nil if recent.empty?

    measurements = recent.map do |m|
      "- #{m.measurement_type.name}: #{m.value} #{m.measurement_type.unit} (#{m.measurement_date.strftime('%b %d')})"
    end.join("\n")

    "[Recent Measurements]\n#{measurements}"
  end

  def build_adherence_risk
    return nil unless defined?(AdherencePredictionService)

    prediction = AdherencePredictionService.new(@account).predict_non_adherence_risk
    risk_level = prediction[:risk_level] || "UNKNOWN"
    risk_factors = prediction[:risk_factors] || []

    factors_text = risk_factors.any? ? "\n  • #{risk_factors.join("\n  • ")}" : "None identified"

    "[Adherence Risk Assessment]\nRisk Level: #{risk_level}\nRisk Factors:#{factors_text}"
  rescue StandardError
    nil
  end

  SCOPE_VIOLATION_PATTERNS = [
    /diagnose/i,
    /prescribe/i,
    /replace.*?(doctor|specialist|physician)/i,
    /specific.*treatment.*plan/i,
    /you\s+should\s+take/i,
    /medical.*emergency/i,
    /go\s+to\s+the\s+er/i,
    /call\s+911/i
  ].freeze

  def detect_scope_violations(content)
    SCOPE_VIOLATION_PATTERNS.select { |pattern| content =~ pattern }
  end

  def log_guardrail_trigger(type, message, persona)
    return unless Rails.env.production? || Rails.configuration.health_agent.enable_guardrail_logging

    Rails.logger.info("[HealthAgent Guardrail] type=#{type} persona=#{persona} account_id=#{@account&.id} message_preview=#{message[0..100]}")
  rescue StandardError => e
    Rails.logger.warn("[HealthAgent Guardrail] Failed to log: #{e.message}")
  end

  def log_scope_violation(violations, content)
    return unless Rails.env.production? || Rails.configuration.health_agent.enable_guardrail_logging

    Rails.logger.warn("[HealthAgent Scope Violation] account_id=#{@account&.id} violations=#{violations.map(&:source).join(', ')} content_preview=#{content[0..200]}")
  rescue StandardError => e
    Rails.logger.warn("[HealthAgent Scope Violation] Failed to log: #{e.message}")
  end

  def append_disclaimer(content, _violations)
    disclaimer = "\n\n---\n*Note: For specific medical decisions, please consult with your healthcare provider. This response is for informational purposes only.*"
    content + disclaimer
  end
end
