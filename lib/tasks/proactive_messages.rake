namespace :proactive do
  desc "Trigger daily health check-in for all patients"
  task daily_checkin: :environment do
    puts "Triggering daily health check-in..."
    DailyHealthCheckinJob.perform_now
    puts "Done. Check HealthAgentMessage records."
  end

  desc "Trigger weekly progress summary for all active patients"
  task weekly_summary: :environment do
    puts "Triggering weekly progress summary..."
    WeeklyProgressSummaryJob.perform_now
    puts "Done. Check HealthAgentMessage records."
  end

  desc "Trigger missed dose follow-up messages"
  task missed_dose_followup: :environment do
    puts "Triggering missed dose follow-up..."
    MissedDoseFollowupJob.perform_now
    puts "Done. Check HealthAgentMessage records."
  end

  desc "Trigger all proactive messages (for demonstration)"
  task trigger_all: :environment do
    Rake::Task["proactive:daily_checkin"].invoke
    Rake::Task["proactive:weekly_summary"].invoke
    Rake::Task["proactive:missed_dose_followup"].invoke
  end
end
