class HealthObservationLog < ApplicationRecord
  belongs_to :account
  belongs_to :specialist, optional: true, class_name: "User"

  enum :observation_type, {
    adherence_trend: "adherence_trend",
    symptom_worsening: "symptom_worsening",
    measurement_anomaly: "measurement_anomaly",
    message_sentiment: "message_sentiment",
    engagement_drop: "engagement_drop"
  }, prefix: :observation

  enum :confidence_level, { low: 0, medium: 1, high: 2 }, prefix: :confidence

  enum :status, { pending: 0, alerting: 1, confirmed: 2, dismissed: 3 }, default: :pending

  def increment_confidence!
    new_level = case confidence_level
                when "low" then "medium"
                when "medium" then "high"
                else "high"
                end
    update!(confidence_level: new_level, observation_count: observation_count + 1)
  end

  def decrement_confidence!
    new_level = case confidence_level
                when "high" then "medium"
                when "medium" then "low"
                else "low"
                end
    update!(confidence_level: new_level)
  end
end
