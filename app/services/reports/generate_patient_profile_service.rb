class Reports::GeneratePatientProfileService
  def initialize(account)
    @account = account
  end

  class PDFGenerationError < StandardError; end

  def call
    pdf_file = Prawn::Document.new do |pdf|
      add_header(pdf)
      add_patient_info(pdf)
      add_medications_section(pdf)
      add_diseases_section(pdf)
      add_measurements_section(pdf)
      add_recent_lab_results(pdf)
      add_adherence_summary(pdf)
      add_footer(pdf)
    end

    pdf_file.render
  end

  private

  def add_header(pdf)
    pdf.text "SALUS HEALTH PORTAL", size: 20, style: :bold, color: "00a884"
    pdf.move_down 10
    pdf.text "Patient Health Profile Report", size: 14, style: :italic
    pdf.text "Generated: #{I18n.l(Time.zone.now, format: '%d %B %Y at %H:%M')}"
    pdf.move_down 20
    pdf.stroke_horizontal_rule
    pdf.move_down 15
  end

  def add_patient_info(pdf)
    pdf.text "PATIENT INFORMATION", size: 12, style: :bold
    pdf.move_down 10

    info = [
      ["Name:", @account.full_name],
      ["Email:", @account.user.email],
      ["Birthday:", @account.birthday ? I18n.l(@account.birthday, format: "%d %B %Y") : "Not provided"],
      ["Location:", "#{@account.city}, #{@account.country}"],
      ["Risk Level:", @account.risk_level],
      ["Account Created:", I18n.l(@account.created_at, format: "%d %B %Y")]
    ]

    table_data = info.map { |label, value| [label, value] }
    pdf.table(table_data, width: 400) do
      columns(0).font_style = :bold
      columns(0).width = 120
      columns(1).width = 280
    end
    pdf.move_down 20
  end

  def add_medications_section(pdf)
    pdf.text "CURRENT MEDICATIONS", size: 12, style: :bold
    pdf.move_down 10

    medications = @account.medications.active.includes(:medication_schedules)

    if medications.any?
      table_data = [%w[Medication Dosage Frequency Instructions]]

      medications.each do |med|
        table_data << [
          med.name,
          med.dosage,
          med.frequency.humanize,
          med.instructions.presence || "-"
        ]
      end

      pdf.table(table_data, header: true, width: 500) do
        columns(0..3).align = :left
      end
    else
      pdf.text "No medications currently active.", size: 10, style: :italic
    end
    pdf.move_down 20
  end

  def add_diseases_section(pdf)
    pdf.text "DIAGNOSED CONDITIONS", size: 12, style: :bold
    pdf.move_down 10

    diseases = @account.diseases.includes(:predefined_disease)

    if diseases.any?
      table_data = [["Condition", "Severity", "Diagnosed Date"]]

      diseases.each do |disease|
        table_data << [
          disease.predefined_disease.name.humanize,
          "Severity: #{disease.severity}/5",
          disease.diagnosed_at ? I18n.l(disease.diagnosed_at, format: "%d %B %Y") : "-"
        ]
      end

      pdf.table(table_data, header: true, width: 400)
    else
      pdf.text "No conditions diagnosed.", size: 10, style: :italic
    end
    pdf.move_down 20
  end

  def add_measurements_section(pdf)
    pdf.text "RECENT MEASUREMENTS", size: 12, style: :bold
    pdf.move_down 10

    measurements = @account.measurements.order(measurement_date: :desc).limit(10).includes(:measurement_type)

    if measurements.any?
      table_data = [%w[Type Value Date]]

      measurements.each do |m|
        table_data << [
          m.measurement_type.name.humanize,
          "#{m.value} #{m.measurement_type.unit.symbol}",
          I18n.l(m.measurement_date, format: "%d %B %Y")
        ]
      end

      pdf.table(table_data, header: true, width: 350)
    else
      pdf.text "No measurements recorded.", size: 10, style: :italic
    end
    pdf.move_down 20
  end

  def add_recent_lab_results(pdf)
    pdf.text "RECENT LAB RESULTS", size: 12, style: :bold
    pdf.move_down 10

    lab_results = @account.respond_to?(:lab_results) ? @account.lab_results.order(result_date: :desc).limit(5) : []

    if lab_results.any?
      table_data = [["Test", "Result", "Reference Range", "Date"]]

      lab_results.each do |lr|
        table_data << [
          lr.test_name,
          lr.result_value,
          "#{lr.reference_range_min} - #{lr.reference_range_max}",
          lr.result_date ? I18n.l(lr.result_date, format: "%d %B %Y") : "-"
        ]
      end

      pdf.table(table_data, header: true, width: 400)
    else
      pdf.text "No lab results on record.", size: 10, style: :italic
    end
    pdf.move_down 20
  end

  def add_adherence_summary(pdf)
    pdf.text "MEDICATION ADHERENCE SUMMARY", size: 12, style: :bold
    pdf.move_down 10

    if @account.respond_to?(:medication_logs)
      recent_logs = @account.medication_logs.where(scheduled_for: 30.days.ago..)
      total = recent_logs.count
      taken = recent_logs.taken.count
      missed = recent_logs.missed.count
      adherence_rate = total.positive? ? ((taken.to_f / total) * 100).round(1) : 100

      summary = [
        ["Period:", "Last 30 days"],
        ["Total Scheduled:", total.to_s],
        ["Taken:", "#{taken} (#{total.positive? ? ((taken.to_f / total) * 100).round(1) : 0}%)"],
        ["Missed:", missed.to_s],
        ["Overall Adherence Rate:", "#{adherence_rate}%"]
      ]
    else
      summary = [
        ["Period:", "Last 30 days"],
        ["Note:", "Medication tracking not available"]
      ]
    end

    table_data = summary.map { |label, value| [label, value] }
    pdf.table(table_data, width: 300)
    pdf.move_down 20
  end

  def add_footer(pdf)
    pdf.stroke_horizontal_rule
    pdf.move_down 10
    pdf.text "This is an automatically generated report from Salus Health Portal.", size: 8, style: :italic
    pdf.text "Please consult with your healthcare provider for medical decisions.", size: 8, style: :italic
    pdf.text "Generated: #{Time.zone.now.iso8601}", size: 8
  end
end
