class AdherencePredictionService
  def initialize(account)
    @account = account
  end

  def calculate_risk_score
    score = 0
    factors = []

    score += medication_factor
    score += measurement_factor
    score += symptom_factor
    score += engagement_factor

    @account.update(risk_score: score, last_risk_assessment: Time.current)

    {
      total_score: score,
      risk_level: risk_level(score),
      factors: factors,
      assessed_at: Time.current
    }
  end

  def predict_non_adherence_risk(period_days = 7)
    recent_logs = @account.medication_logs.where(scheduled_for: period_days.days.ago..)
    return "Insufficient data for prediction." if recent_logs.count < 10

    risk_factors = []

    missed_count = recent_logs.where(status: "missed").count
    missed_rate = (missed_count.to_f / recent_logs.count) * 100
    risk_factors << "High missed dose rate (#{missed_rate.round(1)}%)" if missed_rate > 30

    variance = calculate_time_variance(recent_logs)
    risk_factors << "Irregular medication timing patterns detected" if variance > 0.5

    recent_sequence = @account.behavior_sequences.by_type("medication_adherence").recent.last
    if recent_sequence && recent_sequence.adherence_score < 70
      risk_factors << "Recent low adherence trend (#{recent_sequence.adherence_score}%)"
    end

    days_since_last_log = (Time.current - recent_logs.last.created_at) / 1.day if recent_logs.last
    if days_since_last_log && days_since_last_log > 3
      risk_factors << "No medication logged in #{days_since_last_log.round} days"
    end

    risk_level = if risk_factors.length >= 3
                   "HIGH"
                 elsif risk_factors.length >= 1
                   "MODERATE"
                 else
                   "LOW"
                 end

    {
      risk_level: risk_level,
      risk_factors: risk_factors,
      recommendation: recommendation_for_risk(risk_level),
      predicted_adherence_rate: predict_adherence_rate(recent_logs)
    }
  end

  private

  def medication_factor
    score = 0

    active_meds = @account.medications.active.count
    score += [active_meds * 5, 20].min

    recent_adherence = @account.medication_logs.where(scheduled_for: 30.days.ago..)
    if recent_adherence.any?
      taken_rate = recent_adherence.taken.count.to_f / recent_adherence.count
      score += if taken_rate < 0.7
                 30
               else
                 taken_rate < 0.9 ? 15 : 0
               end
    end

    score
  end

  def measurement_factor
    score = 0

    recent = @account.measurements.where(measured_at: 7.days.ago..)
    score += recent.any? ? 0 : 10

    abnormal_count = @account.measurements.where(measured_at: 30.days.ago..)
                             .count(&:abnormal?)
    score += [abnormal_count * 3, 15].min

    score
  end

  def symptom_factor
    score = 0

    worsening = @account.disease_symptom_updates.where(created_at: 14.days.ago..)
                        .count { |u| u.intensity && u.intensity >= 4 }
    score += [worsening * 5, 20].min

    score
  end

  def engagement_factor
    score = 0

    login_count = 0
    score += [login_count * 2, 10].min

    ai_usage = @account.ai_agent_conversations.where(created_at: 7.days.ago..).count
    score += ai_usage.positive? ? 0 : 5

    score
  end

  def risk_level(score)
    if score >= 50
      "HIGH"
    elsif score >= 25
      "MODERATE"
    else
      "LOW"
    end
  end

  def calculate_time_variance(logs)
    times = logs.where.not(scheduled_for: nil).pluck(:scheduled_for)
    return 0 if times.count < 2

    intervals = times.each_with_index.filter_map do |t, i|
      next nil if i.zero?

      (t - times[i - 1]) / 1.hour
    end

    return 0 if intervals.count < 2

    mean = intervals.sum / intervals.count
    variance = intervals.sum { |i| (i - mean)**2 } / intervals.count
    Math.sqrt(variance)
  end

  def predict_adherence_rate(recent_logs)
    taken = recent_logs.taken.count
    total = recent_logs.count
    total.positive? ? ((taken.to_f / total) * 100).round(1) : 100
  end

  def recommendation_for_risk(risk_level)
    case risk_level
    when "HIGH"
      "Immediate intervention recommended. Please contact your healthcare provider."
    when "MODERATE"
      "Consider setting up reminders or discussing your medication schedule with your doctor."
    else
      "Continue with current habits. You're doing well!"
    end
  end
end
