class BehaviorSequence < ApplicationRecord
  belongs_to :account

  validates :sequence_type, presence: true

  SEQUENCE_TYPES = {
    medication_adherence: "medication_adherence",
    symptom_trend: "symptom_trend",
    measurement_pattern: "measurement_pattern",
    general_health: "general_health"
  }.freeze

  scope :for_account, ->(account) { where(account_id: account.id) }
  scope :recent, -> { where(created_at: 30.days.ago..) }
  scope :by_type, ->(type) { where(sequence_type: type) }
  scope :low_adherence, -> { where(adherence_score: ...70) }

  def record_event(event_type, event_data = {})
    events_list = events || []
    events_list << {
      type: event_type,
      data: event_data,
      timestamp: Time.current.iso8601
    }
    update(events: events_list)
  end

  def calculate_adherence_score
    return 100 if events.blank?

    taken = events.count { |e| e["type"] == "taken" }
    total = events.count
    total.positive? ? ((taken.to_f / total) * 100).round : 100
  end

  def update_risk_level
    score = calculate_adherence_score
    update(adherence_score: score, analyzed_at: Time.current)
    score
  end
end
