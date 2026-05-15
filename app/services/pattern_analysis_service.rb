class PatternAnalysisService
  def initialize(account)
    @account = account
  end

  def analyze_medication_patterns
    sequences = @account.behavior_sequences.by_type("medication_adherence").recent
    return "No medication pattern data available." if sequences.empty?

    summary = []

    avg_score = sequences.average(:adherence_score).to_f.round(1)
    summary << "Medication Pattern Analysis"
    summary << ("=" * 30)
    summary << "Overall Adherence Score: #{avg_score}%"

    sequences_by_day = sequences.group_by { |s| s.created_at.to_date }
    recent_trend = calculate_trend(sequences_by_day)

    summary << "Recent Trend: #{recent_trend}"

    low_adherence = sequences.low_adherence.count
    summary << "\n⚠️ Warning: #{low_adherence} instances of low adherence detected" if low_adherence.positive?

    patterns = detect_time_patterns(sequences)
    if patterns.any?
      summary << "\nDetected Patterns:"
      patterns.each { |p| summary << "- #{p}" }
    end

    summary.join("\n")
  end

  def detect_non_adherence_predictors
    logs = @account.medication_logs.where(scheduled_for: 90.days.ago..)
                   .order(scheduled_for: :asc)

    return "Insufficient data for prediction." if logs.count < 20

    predictors = []

    day_of_week_pattern = analyze_day_pattern(logs)
    predictors << day_of_week_pattern if day_of_week_pattern

    time_of_day_pattern = analyze_time_pattern(logs)
    predictors << time_of_day_pattern if time_of_day_pattern

    consecutive_missed = find_consecutive_misses(logs)
    predictors << "Highest consecutive misses: #{consecutive_missed.max} days" if consecutive_missed.any?

    predictors.any? ? predictors.join("\n") : "No significant predictors found."
  end

  def generate_pattern_report
    summary = []

    summary << "PATIENT BEHAVIOR PATTERN REPORT"
    summary << ("=" * 35)
    summary << "Generated: #{Time.current.strftime('%Y-%m-%d %H:%M')}"
    summary << "\nPatient: #{@account.full_name}"
    summary << ""

    adherence = analyze_medication_patterns
    summary << adherence
    summary << ""

    summary << "\n#{'=' * 35}"
    summary << "PREDICTIVE ANALYSIS"
    summary << ("=" * 35)
    predictors = detect_non_adherence_predictors
    summary << predictors

    summary << "\n#{'=' * 35}"
    summary << "RECOMMENDATIONS"
    summary << ("=" * 35)
    recommendations = generate_recommendations
    summary << recommendations

    summary.join("\n")
  end

  private

  def calculate_trend(sequences_by_day)
    dates = sequences_by_day.keys.sort
    return "stable" if dates.length < 2

    first_half = dates[0...(dates.length / 2)]
    second_half = dates[(dates.length / 2)..]

    first_avg = first_half.filter_map { |d| sequences_by_day[d].average(:adherence_score) }.mean
    second_avg = second_half.filter_map { |d| sequences_by_day[d].average(:adherence_score) }.mean

    diff = second_avg - first_avg
    if diff > 10
      "improving ↑"
    elsif diff < -10
      "declining ↓"
    else
      "stable →"
    end
  end

  def detect_time_patterns(sequences)
    patterns = []

    events = sequences.flat_map(&:events).compact
    return patterns if events.empty?

    hour_counts = Hash.new(0)
    events.each do |event|
      next unless event["timestamp"]

      hour = Time.zone.parse(event["timestamp"]).hour
      hour_counts[hour] += 1
    end

    if hour_counts.any?
      peak_hour = hour_counts.max_by { |_, count| count }
      patterns << "Most active around #{peak_hour[0]}:00"
    end

    patterns
  end

  def analyze_day_pattern(logs)
    day_stats = logs.group_by { |l| l.scheduled_for.wday }
                    .transform_values { |logs| logs.count { |l| l.status == "missed" } }

    worst_day = day_stats.max_by { |_, missed| missed }
    return nil if worst_day[1].zero?

    day_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    "Highest miss rate on #{day_names[worst_day[0]]}"
  end

  def analyze_time_pattern(logs)
    time_stats = logs.group_by { |l| l.scheduled_for.hour }
                     .transform_values { |logs| logs.count { |l| l.status == "missed" } }

    worst_hour = time_stats.max_by { |_, missed| missed }
    return nil if worst_hour[1].zero?

    "Frequently missing doses scheduled for #{worst_hour[0]}:00-#{worst_hour[0] + 1}:00"
  end

  def find_consecutive_misses(logs)
    missed_logs = logs.where(status: "missed").order(:scheduled_for)
    return [] if missed_logs.empty?

    sequences = []
    current_streak = 1

    missed_logs.each_with_index do |log, i|
      next_log = missed_logs[i + 1]
      if next_log && (log.scheduled_for.to_date == next_log.scheduled_for.to_date - 1)
        current_streak += 1
      else
        sequences << current_streak if current_streak > 1
        current_streak = 1
      end
    end

    sequences
  end

  def generate_recommendations
    recommendations = []

    adherence_score = @account.behavior_sequences.by_type("medication_adherence").recent.average(:adherence_score)

    if adherence_score && adherence_score < 70
      recommendations << "1. Consider setting up additional medication reminders"
      recommendations << "2. Discuss with your doctor about simplifying your medication schedule"
    elsif adherence_score && adherence_score >= 90
      recommendations << "1. Continue current medication habits"
      recommendations << "2. Consider sharing your success with others"
    end

    if @account.medications.where(is_active: true).count > 5
      recommendations << "3. Review medications with your doctor to see if any can be consolidated"
    end

    recommendations.any? ? recommendations.join("\n") : "No specific recommendations at this time."
  end
end
