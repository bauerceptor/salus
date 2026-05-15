class HealthAlertService
  attr_reader :account, :specialist

  def initialize(account:, specialist:)
    @account = account
    @specialist = specialist
  end

  def observe_and_assess
    observations = []

    adherence_obs = check_adherence_trend
    observations << adherence_obs if adherence_obs

    symptom_obs = check_symptom_worsening
    observations << symptom_obs if symptom_obs

    engagement_obs = check_engagement_drop
    observations << engagement_obs if engagement_obs

    observations.each { |obs| log_observation(obs) }

    observations.select { |o| confidence_value(o[:confidence]) >= min_confidence_level }.each do |obs|
      create_alert_with_reasoning(obs)
    end

    observations
  end

  def query_patient_status
    adherence = AdherencePredictionService.new(@account).predict_non_adherence_risk
    patterns = PatternAnalysisService.new(@account).generate_pattern_report
    recent_messages = SpecialistMessage.conversation(@account.id, @specialist.id).last(10)

    build_status_summary(adherence: adherence, patterns: patterns, messages: recent_messages)
  end

  CONFIDENCE_LEVELS = { low: 0, medium: 1, high: 2 }.freeze

  private

  def confidence_value(confidence)
    CONFIDENCE_LEVELS[confidence] || 0
  end

  def min_confidence_level
    1
  end

  def min_confidence_threshold
    Rails.configuration.health_agent.min_confidence_threshold || 70
  end

  def observation_window_days
    Rails.configuration.health_agent.observation_window_days || 14
  end

  def check_adherence_trend
    prediction = AdherencePredictionService.new(@account).predict_non_adherence_risk
    return nil unless prediction[:risk_level] == "HIGH"

    {
      type: "adherence_trend",
      confidence: confidence_from_prediction(prediction),
      evidence: prediction[:risk_factors],
      triggered_by: "AdherencePredictionService"
    }
  end

  def check_symptom_worsening
    recent_logs = HealthObservationLog
                  .where(account: @account)
                  .where(created_at: observation_window_days.days.ago..)
                  .order(created_at: :asc)

    symptom_logs = recent_logs.where(observation_type: HealthObservationLog.observation_types[:symptom_worsening])
    return nil if symptom_logs.count < 2

    increasing = symptom_logs.pluck(:confidence_level).each_cons(2).all? do |a, b|
      HealthObservationLog.confidence_levels[b] > HealthObservationLog.confidence_levels[a]
    end
    return nil unless increasing
    return nil unless increasing

    {
      type: "symptom_worsening",
      confidence: :medium,
      evidence: symptom_logs.map { |l| "Symptom worsening observed: #{l.evidence}" },
      triggered_by: "HealthObservationLog"
    }
  end

  def check_engagement_drop
    last_message = SpecialistMessage.for_account(@account).order(created_at: :desc).first
    return nil unless last_message

    days_since_contact = (Time.current - last_message.created_at) / 1.day
    return nil if days_since_contact < observation_window_days

    {
      type: "engagement_drop",
      confidence: days_since_contact > observation_window_days * 2 ? :high : :medium,
      evidence: ["No messages for #{days_since_contact.round(1)} days"],
      triggered_by: "SpecialistMessage"
    }
  end

  def log_observation(obs)
    HealthObservationLog.create!(
      account: @account,
      specialist: @specialist,
      observation_type: obs[:type],
      confidence_level: obs[:confidence],
      evidence: obs[:evidence],
      triggered_by: obs[:triggered_by],
      status: HealthObservationLog.statuses[:pending]
    )
  end

  def create_alert_with_reasoning(obs)
    EmergencyAlert.create!(
      account: @account,
      alert_type: map_observation_to_alert_type(obs[:type]),
      message: build_explainable_alert_message(obs),
      status: EmergencyAlert::STATUSES[:pending]
    )
  end

  def map_observation_to_alert_type(type)
    case type
    when "adherence_trend" then "low_adherence"
    when "engagement_drop" then "no_activity"
    when "symptom_worsening" then "abnormal_measurement"
    else "low_adherence"
    end
  end

  def build_explainable_alert_message(obs)
    <<~TEXT
      [Salus Observation — #{obs[:type].humanize.upcase}]

      Confidence: #{obs[:confidence].to_s.upcase} (#{obs[:evidence].count} confirming signals)

      Evidence:
      #{obs[:evidence].map { |e| "  • #{e}" }.join("\n")}

      Source: #{obs[:triggered_by]}

      Recommended Action: #{recommended_action_for(obs[:type])}
    TEXT
  end

  def recommended_action_for(type)
    case type
    when "adherence_trend" then "Review medication adherence and consider patient outreach"
    when "symptom_worsening" then "Schedule follow-up to assess symptom progression"
    when "engagement_drop" then "Send check-in message to encourage continued engagement"
    else "Review patient status in Salus dashboard"
    end
  end

  def confidence_from_prediction(prediction)
    case prediction[:risk_score]
    when 80.. then :high
    when 50..79 then :medium
    else :low
    end
  end

  def build_status_summary(adherence:, patterns:, messages:)
    {
      adherence_risk: adherence[:risk_level],
      risk_score: adherence[:risk_score],
      risk_factors: adherence[:risk_factors],
      pattern_summary: patterns[:summary] || "No significant patterns detected",
      recent_messages_count: messages.count,
      last_contact: messages.last&.created_at,
      recommended_actions: build_recommended_actions(adherence, patterns)
    }
  end

  def build_recommended_actions(adherence, patterns)
    actions = []
    actions << "Review medication adherence" if adherence[:risk_level] == "HIGH"
    actions << "Schedule follow-up appointment" if patterns[:risk_factors]&.include?("declining")
    actions << "Consider specialist outreach" if adherence[:risk_score] > 70
    actions.empty? ? ["Continue monitoring"] : actions
  end
end
