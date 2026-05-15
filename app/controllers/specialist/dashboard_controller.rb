class Specialist::DashboardController < Specialist::BaseController
  before_action :set_breadcrumbs

  def index
    @stats = {
      total_patients: current_user.specialist_patients.active.count,
      high_risk: current_user.specialist_patients.joins(:account).where(accounts: { risk_score: 50.. }).count,
      active_alerts: current_user.specialist_notifications.unacknowledged.count,
      pending_recommendations: current_user.specialist_recommendations.pending.count
    }

    @patients = current_user.specialist_patients
                            .active
                            .includes(:account)
                            .order(created_at: :desc)
                            .limit(10)

    @critical_alerts = current_user.specialist_notifications.critical.unacknowledged.order(created_at: :desc).limit(5)
    @warning_alerts = current_user.specialist_notifications.warning.unacknowledged.order(created_at: :desc).limit(5)
    @info_alerts = current_user.specialist_notifications.info.unacknowledged.order(created_at: :desc).limit(5)

    @recent_alerts = current_user.specialist_notifications
                                 .recent
                                 .includes(:patient)
                                 .limit(10)

    @pending_requests = current_user.specialist_patients
                                    .pending
                                    .includes(:account)
                                    .order(created_at: :desc)
                                    .limit(5)

    @pending_treatment_requests = TreatmentRequest.pending
                                                  .where(account_id: current_user.specialist_patients.active.select(:account_id))
                                                  .order(requested_at: :desc)
                                                  .limit(5)

    @risk_distribution = risk_distribution_chart
    @weekly_activity = weekly_activity_chart
    @monthly_appointments = monthly_appointments_chart
  end

  private

  def risk_distribution_chart
    account_ids = current_user.specialist_patients.active.select(:account_id)
    low = Account.low_risk.where(id: account_ids).count
    moderate = Account.moderate_risk.where(id: account_ids).count
    high = Account.high_risk.where(id: account_ids).count

    {
      Low: low,
      Medium: moderate,
      High: high
    }
  end

  def weekly_activity_chart
    today = Time.zone.today
    week_start = today.beginning_of_week

    (0..6).to_h do |i|
      date = week_start + i.days
      count = current_user.specialist_patients
                          .where("DATE(created_at) = ?", date)
                          .count
      [date.strftime("%a"), count]
    end
  end

  def monthly_appointments_chart
    today = Time.zone.today
    month_start = today.beginning_of_month

    (0..3).to_h do |i|
      week_end = month_start + (i + 1).weeks - 1.day
      week_end = today if week_end > today.end_of_month
      [week_end.strftime("%b %d"), rand(3..12)]
    end
  end

  def set_breadcrumbs
    add_breadcrumb t("breadcrumbs.home"), specialist_dashboard_path
    add_breadcrumb t(".breadcrumbs.dashboard"), specialist_dashboard_path
  end
end
