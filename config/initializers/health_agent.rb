Rails.application.config.health_agent = Struct.new(
  :patient_rag_enabled,
  :pattern_rag_enabled,
  :min_confidence_threshold,
  :alert_cooldown_hours,
  :observation_window_days
).new(
  patient_rag_enabled: ENV.fetch("HEALTH_AGENT_PATIENT_RAG_ENABLED", "true") == "true",
  pattern_rag_enabled: ENV.fetch("HEALTH_AGENT_PATTERN_RAG_ENABLED", "true") == "true",
  min_confidence_threshold: ENV.fetch("HEALTH_AGENT_MIN_CONFIDENCE_THRESHOLD", "70").to_i,
  alert_cooldown_hours: ENV.fetch("HEALTH_AGENT_ALERT_COOLDOWN_HOURS", "24").to_i,
  observation_window_days: ENV.fetch("HEALTH_AGENT_OBSERVATION_WINDOW_DAYS", "14").to_i
)
