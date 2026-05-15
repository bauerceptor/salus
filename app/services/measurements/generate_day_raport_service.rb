class Measurements::GenerateDayRaportService
  def initialize(date, account)
    @date = date
    @account = account
  end

  class PDFGenerationError < StandardError; end

  def call
    measurements = load_measurements
    pdf_data = generate_summarized_pdf(measurements)

    if (measurement_raport = find_existing_raport)
      measurement_raport.attachment = StringIO.new(pdf_data)
    else
      raport_name = "Measurement report from #{I18n.l(@date, format: '%d %B %Y')}"
      measurement_raport = @account.measurement_raports.build(
        name: raport_name, raport_type: "day", attachment: StringIO.new(pdf_data)
      )
    end
    measurement_raport.attachment.metadata["filename"] = "measurements_day_#{Time.zone.now.to_i}.pdf"
    measurement_raport.save!
    { measurement_raport: measurement_raport, pdf_data: pdf_data }
  end

  private

  def load_measurements
    @account
      .measurements
      .includes(measurement_type: :unit)
      .where(measurement_date: @date.all_day)
      .order(measurement_date: :asc)
  end

  def find_existing_raport
    raport_name = "Measurement report from #{I18n.l(@date, format: '%d %B %Y')}"
    @account.measurement_raports.find_by(name: raport_name)
  end

  def generate_summarized_pdf(measurements)
    summary = calculate_summary(measurements)

    pdf_file = Prawn::Document.new do |pdf|
      pdf.font "Helvetica"

      pdf.text "#{@account.full_name} (#{@account.user.email})", size: 14
      pdf.move_down 10
      pdf.text "Measurement Report - #{I18n.l(@date, format: '%d %B %Y')}", size: 16, style: :bold
      pdf.text "Generated: #{I18n.l(Time.zone.now, format: '%H:%M, %d %B %Y')}", size: 10
      pdf.move_down 20

      pdf.text "Summary", size: 14, style: :bold
      pdf.move_down 10
      pdf.text "Total Measurements: #{summary[:total]}"
      pdf.text "Measurement Types: #{summary[:types_count]}"
      pdf.text "Within Limits: #{summary[:within_limits]}"
      pdf.text "Out of Limits: #{summary[:out_of_limits]}"
      pdf.move_down 20

      pdf.text "Statistics by Type", size: 14, style: :bold
      pdf.move_down 10

      summary[:by_type].each do |type_name, data|
        type_label = I18n.t("activerecord.attributes.measurement_types.#{type_name}")
        pdf.text "#{type_label}:", style: :bold
        pdf.text "  Count: #{data[:count]}"
        pdf.text "  Latest: #{data[:latest][:value]} #{data[:latest][:unit]}" if data[:latest]
        pdf.text "  Min: #{data[:min][:value]} #{data[:min][:unit]}" if data[:min]
        pdf.text "  Max: #{data[:max][:value]} #{data[:max][:unit]}" if data[:max]
        pdf.text "  Average: #{data[:avg].round(1)} #{data[:latest][:unit]}" if data[:avg] && data[:latest]
        pdf.move_down 5
      end

      pdf.move_down 10
      pdf.text "All Measurements", size: 14, style: :bold
      pdf.move_down 10

      table_data = [%w[Time Type Value Unit Status]]
      measurements.each do |m|
        type = I18n.t("activerecord.attributes.measurement_types.#{m.measurement_type.name}")
        status = m.is_within_limits ? "OK" : "WARNING"
        table_data << [
          I18n.l(m.measurement_date, format: "%H:%M"),
          type,
          m.value,
          m.measurement_type.unit.symbol,
          status
        ]
      end

      pdf.table(table_data, header: true, row_colors: %w[F0F0F0 FFFFFF]) do
        columns([0, 2, 3]).align = :right
        columns([4]).align = :center
      end
    end

    pdf_file.render
  end

  def calculate_summary(measurements)
    total = measurements.count
    within_limits = measurements.count(&:is_within_limits)

    by_type = {}
    measurements.group_by(&:measurement_type).each do |type, type_measurements|
      values = type_measurements.map { |m| m.value.to_f }
      by_type[type.name] = {
        count: type_measurements.count,
        latest: { value: type_measurements.last.value, unit: type.unit.symbol },
        min: { value: type_measurements.min_by { |m| m.value.to_f }.value, unit: type.unit.symbol },
        max: { value: type_measurements.max_by { |m| m.value.to_f }.value, unit: type.unit.symbol },
        avg: values.sum / values.count.to_f
      }
    end

    {
      total: total,
      types_count: by_type.keys.count,
      within_limits: within_limits,
      out_of_limits: total - within_limits,
      by_type: by_type
    }
  end
end
