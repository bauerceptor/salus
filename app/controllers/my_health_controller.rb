class MyHealthController < BaseController
  before_action :set_breadcrumbs

  def index
    @pagy, @posts = pagy(
      DiseaseStatus
      .joins(disease: %i[account predefined_disease])
      .includes(:comments, :reactions, disease: %i[account predefined_disease])
      .where(disease: { account_id: current_account.friends.pluck(:id) + [current_account.id] })
      .order(updated_at: :desc),
      items: 10
    )

    @liked_statuses = Reaction.where(
      account: current_account,
      reaction_type: "like",
      reactable_type: "DiseaseStatus"
    ).pluck(:reactable_id)

    @care_team = current_account.specialist_patients.active.includes(specialist: :account)
    @pending_recommendations = current_account.specialist_recommendations.pending.count
    @unread_specialist_messages = current_account.specialist_messages.from_specialist.unread.count

    load_measurement_charts
  end

  private

  def set_breadcrumbs
    add_breadcrumb t("breadcrumbs.home"), authenticated_root_path
  end

  def load_measurement_charts
    @measurement_types = MeasurementType.all
    period = (params[:period] || 30).to_i.days

    @chart_data = {}
    @measurement_types.each do |type|
      measurements = current_account.measurements
                                    .where(measurement_type: type)
                                    .where(measurement_date: period.ago..)
                                    .order(:measurement_date)

      @chart_data[type.name] = {
        labels: measurements.pluck(:measurement_date).map { |d| d.strftime("%m/%d") },
        values: measurements.pluck(:value),
        unit: type.unit&.symbol || ""
      }
    end
  end
end
