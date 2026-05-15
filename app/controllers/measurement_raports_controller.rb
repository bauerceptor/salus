class MeasurementRaportsController < BaseController
  before_action :set_measurement_raport, only: %i[show destroy]
  before_action :set_breadcrumbs

  def index
    @pagy, @raports = pagy(current_account.measurement_raports)
  end

  def show
    respond_to do |format|
      format.html do
        load_report_data
        add_breadcrumb @measurement_raport.name, measurement_raport_path(@measurement_raport)
      end
      format.pdf do
        load_report_data
        pdf_data = Measurements::GenerateDayRaportService.new(@report_date, current_account).call[:pdf_data]
        send_data(
          pdf_data,
          filename: @measurement_raport.attachment.metadata["filename"],
          type: "application/pdf",
          disposition: "attachment"
        )
      end
    end
  end

  def generate_for_day
    date = Date.parse(params[:day])
    result = Measurements::GenerateDayRaportService.new(date, current_account).call

    respond_to do |format|
      format.html do
        redirect_to measurement_raport_path(id: result[:measurement_raport].id, locale: I18n.locale),
                    notice: t(".success")
      end
    rescue Date::Error
      redirect_to measurements_path, alert: "Invalid date format"
    rescue StandardError => e
      redirect_to measurement_raports_path, alert: "Failed to generate report: #{e.message}"
    end
  end

  def destroy
    @measurement_raport.destroy

    respond_to do |format|
      format.html do
        redirect_to measurement_raports_path, notice: t(".success")
      end
    end
  end

  private

  def set_measurement_raport
    @measurement_raport = current_account.measurement_raports.find(params[:id])
  end

  def load_report_data
    @report_date = extract_date_from_name(@measurement_raport.name)
    @measurements = current_account.measurements
                                   .includes(measurement_type: :unit)
                                   .where(measurement_date: @report_date.all_day)
                                   .order(measurement_date: :asc)

    @total_measurements = @measurements.count
    @measurement_types_count = @measurements.pluck(:measurement_type_id).uniq.count
    @within_limits = @measurements.count(&:is_within_limits)
    @out_of_limits = @total_measurements - @within_limits

    @measurements_by_type = {}
    @measurements.group_by(&:measurement_type).each do |type, type_measurements|
      values = type_measurements.map(&:value).map(&:to_f)
      @measurements_by_type[type.name] = {
        count: type_measurements.count,
        latest: type_measurements.max_by(&:measurement_date),
        min: type_measurements.min_by { |m| m.value.to_f },
        max: type_measurements.max_by { |m| m.value.to_f },
        avg: values.sum / values.count.to_f,
        within_limits: type_measurements.count(&:is_within_limits)
      }
    end
  end

  def extract_date_from_name(name)
    date_match = name.match(/(\d{1,2})\s+(\w+)\s+(\d{4})/)
    if date_match
      Date.parse("#{date_match[1]} #{date_match[2]} #{date_match[3]}")
    else
      Time.zone.today
    end
  rescue StandardError
    Time.zone.today
  end

  def set_rack_response((status, headers, body))
    self.status = status
    self.headers.merge!(headers)
    self.response_body = body
  end

  def set_breadcrumbs
    add_breadcrumb t("breadcrumbs.home"), authenticated_root_path
    add_breadcrumb t("measurements.breadcrumbs.index"), measurements_path
    add_breadcrumb t(".breadcrumbs.index"), measurement_raports_path
  end
end
