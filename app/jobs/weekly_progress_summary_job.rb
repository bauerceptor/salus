class WeeklyProgressSummaryJob < ApplicationJob
  queue_as :default

  def perform
    Account.find_each do |account|
      next unless has_recent_activity?(account)

      conversation = HealthAgentConversation.find_or_create_by!(
        account: account,
        persona: :patient,
        status: :active
      )

      response = generate_summary_for(account)

      next unless response

      message = HealthAgentMessage.create!(
        conversation: conversation,
        role: :assistant,
        content: response
      )

      broadcast_to_account(account, message)
    rescue StandardError => e
      Rails.logger.error("[WeeklyProgressSummaryJob] Failed for account #{account.id}: #{e.message}")
    end
  end

  private

  def has_recent_activity?(account)
    recent_cutoff = 7.days.ago

    account.medication_logs.where("created_at >= ?", recent_cutoff).any? ||
      account.measurements.where("measurement_date >= ?", recent_cutoff).any?
  end

  def generate_summary_for(account)
    adherence_data = fetch_adherence_data(account)
    measurement_data = fetch_measurement_data(account)

    prompt = build_summary_prompt(account, adherence_data, measurement_data)

    ProactiveAgentService.call(prompt: prompt, account: account)
  end

  def fetch_adherence_data(account)
    recent_cutoff = 7.days.ago
    logs = account.medication_logs.where("scheduled_for >= ?", recent_cutoff)

    total = logs.count
    taken = logs.where(status: :taken).count

    {
      total: total,
      taken: taken,
      rate: total.positive? ? ((taken.to_f / total) * 100).round : 0
    }
  end

  def fetch_measurement_data(account)
    recent_cutoff = 7.days.ago
    measurements = account.measurements.where("measurement_date >= ?", recent_cutoff)

    grouped = measurements.group_by(&:measurement_type_id)

    grouped.each_with_object({}) do |(type_id, records), hash|
      next if records.empty?

      type = records.first.measurement_type
      values = records.map(&:value).compact.map(&:to_f)

      hash[type.name] = {
        count: values.size,
        average: values.sum / values.size,
        unit: type.unit
      }
    end
  end

  def build_summary_prompt(account, adherence_data, measurement_data)
    summary_parts = []

    summary_parts << "Weekly Progress Summary for #{account.full_name}:"
    summary_parts << "- Medication adherence: #{adherence_data[:taken]}/#{adherence_data[:total]} doses taken (#{adherence_data[:rate]}% adherence)"

    if measurement_data.any?
      summary_parts << "- Recent measurements:"
      measurement_data.each do |name, data|
        summary_parts << "  * #{name}: avg #{data[:average].round(1)} #{data[:unit]} (#{data[:count]} readings)"
      end
    else
      summary_parts << "- No measurements recorded this week"
    end

    prompt = summary_parts.join("\n")
    prompt + "\n\nWrite a warm, encouraging summary of this week's health progress. " \
              "Highlight any positive trends. Mention any concerns gently. " \
              "Remind them their specialist is available if needed. Keep it conversational, 3-5 sentences max."
  end

  def broadcast_to_account(account, message)
    NotificationsChannel.broadcast_to(
      account,
      {
        id: message.id,
        type: "weekly_summary",
        content: message.content.truncate(100),
        created_at: message.created_at.iso8601
      }
    )
  end
end
