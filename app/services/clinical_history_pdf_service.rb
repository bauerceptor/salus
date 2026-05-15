class ClinicalHistoryPdfService
  class PDFGenerationError < StandardError; end

  def initialize(account, specialist)
    @account = account
    @specialist = specialist
  end

  def call
    pdf_file = Prawn::Document.new do |pdf|
      add_header(pdf)
      add_patient_info(pdf)
      add_ai_clinical_summary(pdf)
      add_diseases_section(pdf)
      add_medications_section(pdf)
      add_treatments_section(pdf)
      add_measurements_section(pdf)
      add_adherence_summary(pdf)
      add_care_history_section(pdf)
      add_specialist_notes_section(pdf)
      add_footer(pdf)
    end

    pdf_file.render
  rescue StandardError => e
    raise PDFGenerationError, "Failed to generate PDF: #{e.message}"
  end

  private

  attr_reader :account, :specialist

  def add_header(pdf)
    pdf.text "SALUS HEALTH PORTAL", size: 20, style: :bold, color: "00a884"
    pdf.move_down 10
    pdf.text "Clinical History Report", size: 14, style: :italic
    pdf.text "Generated: #{I18n.l(Time.zone.now, format: '%d %B %Y at %H:%M')}"
    pdf.move_down 20
    pdf.stroke_horizontal_rule
    pdf.move_down 15
  end

  def add_patient_info(pdf)
    pdf.text "PATIENT INFORMATION", size: 12, style: :bold
    pdf.move_down 10

    info = [
      ["Name:", account.full_name],
      ["Location:", "#{account.city}, #{account.country}"],
      ["Risk Level:", account.risk_level],
      ["Risk Score:", (account.risk_score || 0).to_s],
      ["Account Created:", I18n.l(account.created_at, format: "%d %B %Y")]
    ]

    table_data = info.map { |label, value| [label, value] }
    pdf.table(table_data, width: 400) do
      columns(0).font_style = :bold
      columns(0).width = 120
      columns(1).width = 280
    end
    pdf.move_down 20
  end

  def add_ai_clinical_summary(pdf)
    pdf.text "AI CLINICAL SUMMARY", size: 12, style: :bold
    pdf.move_down 10

    summary = ClinicalSummaryService.new(account).generate_summary_text
    pdf.text summary, size: 10, style: :italic
    pdf.move_down 20
  rescue StandardError
    pdf.text "AI summary unavailable.", size: 10, style: :italic
    pdf.move_down 20
  end

  def add_diseases_section(pdf)
    pdf.text "DIAGNOSED CONDITIONS", size: 12, style: :bold
    pdf.move_down 10

    diseases = account.diseases.includes(:predefined_disease)

    if diseases.any?
      table_data = [["Condition", "Severity", "Diagnosed Date"]]

      diseases.each do |disease|
        table_data << [
          disease.predefined_disease&.name || disease.name || "Unknown",
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

  def add_medications_section(pdf)
    pdf.text "CURRENT MEDICATIONS", size: 12, style: :bold
    pdf.move_down 10

    medications = account.medications.active.includes(%i[medication_request specialist_recommendation])

    if medications.any?
      table_data = [%w[Medication Dosage Frequency Source]]

      medications.each do |med|
        source_label = case med.source
                       when "patient_request" then "Patient Request"
                       when "doctor_prescription" then "Doctor Prescription"
                       else "-"
                       end

        table_data << [
          med.name,
          med.dosage,
          med.frequency.humanize,
          source_label
        ]
      end

      pdf.table(table_data, header: true, width: 450) do
        columns(0..3).align = :left
      end
    else
      pdf.text "No medications currently active.", size: 10, style: :italic
    end
    pdf.move_down 20
  end

  def add_treatments_section(pdf)
    pdf.text "TREATMENTS", size: 12, style: :bold
    pdf.move_down 10

    treatments = account.treatments.where(approval_status: "approved")

    if treatments.any?
      table_data = [["Treatment", "Status", "Start Date"]]

      treatments.each do |treatment|
        table_data << [
          treatment.title,
          treatment.status.humanize,
          treatment.start_date ? I18n.l(treatment.start_date, format: "%d %B %Y") : "-"
        ]
      end

      pdf.table(table_data, header: true, width: 400)
    else
      pdf.text "No approved treatments.", size: 10, style: :italic
    end
    pdf.move_down 20
  end

  def add_measurements_section(pdf)
    pdf.text "RECENT MEASUREMENTS (90 DAYS)", size: 12, style: :bold
    pdf.move_down 10

    from_date = 90.days.ago
    measurements = account.measurements
                          .where(measurement_date: from_date..)
                          .order(measurement_date: :desc)
                          .limit(20)
                          .includes(:measurement_type)

    if measurements.any?
      table_data = [%w[Type Value Date]]

      measurements.each do |m|
        table_data << [
          m.measurement_type.name.humanize,
          m.value.to_s,
          I18n.l(m.measurement_date, format: "%d %B %Y")
        ]
      end

      pdf.table(table_data, header: true, width: 350)
    else
      pdf.text "No measurements recorded in the last 90 days.", size: 10, style: :italic
    end
    pdf.move_down 20
  end

  def add_adherence_summary(pdf)
    pdf.text "MEDICATION ADHERENCE SUMMARY", size: 12, style: :bold
    pdf.move_down 10

    recent_logs = MedicationLog.for_account(account).where(scheduled_for: 30.days.ago..)
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

    table_data = summary.map { |label, value| [label, value] }
    pdf.table(table_data, width: 300)
    pdf.move_down 20
  end

  def add_care_history_section(pdf)
    pdf.text "CARE HISTORY (30 DAYS)", size: 12, style: :bold
    pdf.move_down 10

    care_events = PatientCareHistoryService.new(account, scope: :recent).events

    if care_events.any?
      care_events.first(15).each do |event|
        pdf.text event[:title].to_s, size: 10, style: :bold
        pdf.text "  #{event[:description]}", size: 9
        pdf.text "  #{I18n.l(event[:timestamp], format: '%d %B %Y')}", size: 8, style: :italic
        pdf.move_down 5
      end

      pdf.text "... and #{care_events.length - 15} more events", size: 9, style: :italic if care_events.length > 15
    else
      pdf.text "No care history events in the last 30 days.", size: 10, style: :italic
    end

    pdf.move_down 20
  end

  def add_specialist_notes_section(pdf)
    pdf.text "SPECIALIST NOTES", size: 12, style: :bold
    pdf.move_down 10

    specialist_user = specialist.is_a?(User) ? specialist : specialist.user if specialist
    notes = specialist_user&.specialist_notes&.for_patient(account)&.order(created_at: :desc)&.limit(10)

    if notes&.any?
      notes.each do |note|
        pdf.text "#{note.note_type.humanize} - #{I18n.l(note.created_at, format: '%d %B %Y')}", size: 9, style: :bold
        pdf.text "  #{note.content}", size: 10
        pdf.move_down 5
      end
    else
      pdf.text "No specialist notes for this patient.", size: 10, style: :italic
    end

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
