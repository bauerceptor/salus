class DashboardController < BaseController
  before_action :set_breadcrumbs

  def index
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
