class ClinicalSummaryService
  def initialize(account, specialist: nil)
    @account = account
    @specialist = specialist
  end

  def call
    {
      summary_text: generate_summary_text,
      generated_at: Time.zone.now,
      confidence: confidence_level
    }
  end

  def generate_summary_text
    patient_context = build_patient_context
    return "Insufficient patient data for AI summary." if patient_context.blank?

    agent_service = HealthAgentService.new(account: @account, specialist: @specialist)
    prompt = build_summary_prompt(patient_context)

    begin
      agent_service.ask(prompt, persona: :specialist)
    rescue StandardError => e
      "AI summary unavailable: #{e.message}"
    end
  end

  private

  attr_reader :account, :specialist

  def build_patient_context
    context_parts = []
    context_parts << build_disease_context if account.diseases.any?
    context_parts << build_medication_context if account.medications.any?
    context_parts << build_measurement_context if account.measurements.any?
    context_parts << build_adherence_context if defined?(MedicationLog)

    context_parts.join("\n\n")
  end

  def build_disease_context
    diseases = account.diseases.includes(:predefined_disease).map do |d|
      name = d.predefined_disease&.name || d.name || "Unknown"
      "  - #{name} (severity: #{d.severity}/5)"
    end.join("\n")

    "Diagnosed Conditions:\n#{diseases}"
  end

  def build_medication_context
    meds = account.medications.active.map do |m|
      "  - #{m.name} (#{m.dosage}) - #{m.frequency.humanize}"
    end.join("\n")

    "Current Medications:\n#{meds}"
  end

  def build_measurement_context
    recent = account.measurements.order(measurement_date: :desc).limit(5).includes(:measurement_type)
    measurements = recent.map do |m|
      "  - #{m.measurement_type.name}: #{m.value} on #{m.measurement_date.strftime('%b %d')}"
    end.join("\n")

    "Recent Measurements:\n#{measurements}"
  end

  def build_adherence_context
    logs = MedicationLog.for_account(account).where(scheduled_for: 30.days.ago..)
    return nil if logs.empty?

    total = logs.count
    taken = logs.taken.count
    rate = total.positive? ? ((taken.to_f / total) * 100).round(1) : 100

    "30-Day Adherence: #{rate}% (#{taken}/#{total} taken)"
  end

  def build_summary_prompt(patient_context)
    <<~PROMPT
      Based on the following patient data, provide a concise clinical summary highlighting
      key health trends, notable concerns, and recommended focus areas for the specialist.

      #{patient_context}

      Please provide:
      1. Key health observations
      2. Areas of concern
      3. Suggested monitoring priorities

      Keep the summary brief (3-5 sentences) and clinically relevant.
    PROMPT
  end

  def confidence_level
    data_points = 0
    data_points += 1 if account.diseases.any?
    data_points += 1 if account.medications.any?
    data_points += 1 if account.measurements.any?
    data_points += 1 if defined?(MedicationLog) && MedicationLog.for_account(account).any?

    case data_points
    when 0..1 then "low"
    when 2..3 then "medium"
    else "high"
    end
  end
end
