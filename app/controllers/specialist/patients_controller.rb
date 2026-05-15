class Specialist::PatientsController < Specialist::BaseController
  before_action :set_breadcrumbs

  def index
    @pagy, @patients = pagy(
      patient_scope,
      from: 1
    )
  end

  def show
    @patient = Account.find(params[:id])
    @specialist_patient = current_user.specialist_patients.find_by!(account: @patient)

    @notes = current_user.specialist_notes.for_patient(@patient).order(created_at: :desc)
    @recommendations = current_user.specialist_recommendations.for_patient(@patient).order(created_at: :desc)
    @pending_treatment_requests = TreatmentRequest.pending.for_account(@patient)
    @messages = SpecialistMessage.where(account: @patient, specialist: current_user)
                                 .order(created_at: :desc)
                                 .limit(10)

    @period = [7, 30, 90].include?(params[:period].to_i) ? params[:period].to_i : 30
    @chart_data = build_chart_data(@patient, @period)

    @adherence_prediction = Rails.cache.fetch("adherence_prediction/#{@patient.id}", expires_in: 1.hour) do
      AdherencePredictionService.new(@patient).predict_non_adherence_risk(7)
    end

    @stats = {
      adherence: calculate_adherence(@patient),
      risk_score: @patient.risk_score || 0,
      diseases_count: @patient.diseases.count,
      medications_count: @patient.medications.count
    }

    @care_history_scope = params[:history] == "full" ? :full : :recent
    @care_history = PatientCareHistoryService.new(@patient, scope: @care_history_scope).events
  end

  def search
    @patients = current_user.specialist_patients.active
                            .joins(:account)
                            .where("accounts.first_name ILIKE ? OR accounts.last_name ILIKE ?",
                                   "%#{params[:q]}%", "%#{params[:q]}%")
                            .order("accounts.first_name ASC")
                            .limit(10)
                            .map(&:account)

    render partial: "specialist/shared/search_results", locals: { patients: @patients }, layout: false
  end

  def export_fhir
    @patient = Account.find(params[:id])
    current_user.specialist_patients.find_by!(account: @patient)

    exporter = Fhir::Export::BundleExporter.new(@patient)
    send_data exporter.to_fhir_json,
              type: "application/json",
              disposition: "attachment; filename=\"patient_#{@patient.id}_fhir.json\""
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def import_fhir
    @patient = Account.find(params[:id])
    current_user.specialist_patients.find_by!(account: @patient)

    file = params[:file]
    unless file
      render json: { error: "No file uploaded." }, status: :unprocessable_content
      return
    end

    begin
      json_string = file.read
      importer = Fhir::Import::BundleImporter.from_json(json_string, @patient.id, uploaded_by_id: current_user.id)
      result = importer.import_all
      if request.format.json?
        render json: { message: "FHIR data imported successfully.", result: }
      else
        redirect_to specialist_patient_path(id: @patient.id, locale: I18n.locale), notice: "FHIR data imported successfully."
      end
    rescue JSON::ParserError => e
      render json: { error: "Invalid JSON: #{e.message}" }, status: :unprocessable_content
    rescue StandardError => e
      render json: { error: "Import failed: #{e.message}" }, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def import_document
    @patient = Account.find(params[:id])
    current_user.specialist_patients.find_by!(account: @patient)

    file = params[:file]
    unless file
      render json: { error: "No file uploaded." }, status: :unprocessable_content
      return
    end

    unless file.content_type == "application/pdf" || file.content_type.include?("pdf")
      render json: { error: "Only PDF files are supported." }, status: :unprocessable_content
      return
    end

    begin
      pdf_data = file.read
      document_type = params[:document_type].presence || "other"

      unless ClinicalDocument::DOCUMENT_TYPES.include?(document_type)
        render json: { error: "Invalid document type. Must be one of: #{ClinicalDocument::DOCUMENT_TYPES.join(', ')}" }, status: :unprocessable_content
        return
      end

      importer = Fhir::Import::DocumentReferenceImporter.new(
        build_fhir_document_reference(pdf_data, file.original_filename, document_type),
        @patient.id,
        current_user.id
      )

      document = importer.to_local

      if document
        render json: { message: "Document imported successfully.", document_id: document.id }
      else
        render json: { error: "Failed to import document." }, status: :unprocessable_content
      end
    rescue StandardError => e
      Rails.logger.error "Document import error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      render json: { error: "Import failed: #{e.message}" }, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def report
    @patient = Account.find(params[:id])
    current_user.specialist_patients.find_by!(account: @patient)

    pdf_data = SpecialistPatientReportService.new(@patient, current_user).call

    filename = "patient_report_#{@patient.id}_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.pdf"

    send_data pdf_data,
              type: "application/pdf",
              disposition: "attachment; filename=\"#{filename}\""
  rescue ActiveRecord::RecordNotFound
    head :not_found
  rescue SpecialistPatientReportService::PDFGenerationError => e
    redirect_to specialist_patient_path(id: params[:id], locale: I18n.locale), alert: "Failed to generate report: #{e.message}"
  end

  def clinical_history
    @patient = Account.find(params[:id])
    current_user.specialist_patients.find_by!(account: @patient)

    pdf_data = ClinicalHistoryPdfService.new(@patient, current_user).call

    filename = "clinical_history_#{@patient.id}_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.pdf"

    send_data pdf_data,
              type: "application/pdf",
              disposition: "attachment; filename=\"#{filename}\""
  rescue ActiveRecord::RecordNotFound
    head :not_found
  rescue ClinicalHistoryPdfService::PDFGenerationError => e
    redirect_to specialist_patient_path(id: params[:id], locale: I18n.locale), alert: "Failed to generate report: #{e.message}"
  end

  def update
    @patient = Account.find(params[:id])
    @specialist_patient = current_user.specialist_patients.find_by!(account: @patient)

    return if params[:status].blank?

    if params[:status] == "active"
      @specialist_patient.approve!
      redirect_to specialist_patient_path(id: @patient.id, locale: I18n.locale), notice: "Patient request approved."
    else
      @specialist_patient.reject!
      redirect_to specialist_dashboard_path, notice: "Patient request rejected."
    end
  end

  private

  def patient_scope
    scope = current_user.specialist_patients.active.includes(:account)

    scope = scope.where(accounts: { risk_level: risk_filter_param }) if risk_filter_param
    scope = scope.joins(:account).where("accounts.full_name ILIKE ?", "%#{query_param}%") if query_param

    scope.order(created_at: :desc)
  end

  def query_param
    params[:q].presence
  end

  def risk_filter_param
    %w[Low Medium High].find { |level| level == params[:risk_filter] }
  end

  def set_breadcrumbs
    add_breadcrumb "Home", specialist_dashboard_path
    add_breadcrumb "Dashboard", specialist_dashboard_path
    add_breadcrumb "Patients", specialist_patients_path
    add_breadcrumb @patient&.full_name, (specialist_patient_path(id: @patient.id, locale: I18n.locale) if @patient)
  end

  def calculate_adherence(patient)
    logs = patient.medication_logs.where(created_at: 30.days.ago..)
    total = logs.count
    taken = logs.where.not(taken_at: nil).count
    total.positive? ? ((taken.to_f / total) * 100).round : 100
  end

  def build_chart_data(account, period)
    measurement_types = MeasurementType.all
    from = period.days.ago

    chart_data = {}
    measurement_types.each do |type|
      measurements = account.measurements
                            .where(measurement_type: type)
                            .where(measurement_date: from..)
                            .order(:measurement_date)

      chart_data[type.name] = {
        labels: measurements.pluck(:measurement_date).map { |d| d.strftime("%m/%d") },
        values: measurements.pluck(:value),
        unit: type.unit&.symbol || ""
      }
    end
    chart_data
  end

  def build_fhir_document_reference(pdf_data, filename, document_type)
    require "base64"

    doc_type_mapping = {
      "lab_result" => { system: "http://loinc.org", code: "34746-6", display: "Laboratory Result" },
      "imaging_report" => { system: "http://loinc.org", code: "34117-2", display: "Imaging Report" },
      "clinical_note" => { system: "http://loinc.org", code: "34122-2", display: "Clinical Note" },
      "discharge_summary" => { system: "http://loinc.org", code: "28654-3", display: "Discharge Summary" },
      "other" => { system: "http://loinc.org", code: "_other", display: "Other Document" }
    }

    type_info = doc_type_mapping[document_type] || doc_type_mapping["other"]

    OpenStruct.new(
      resourceType: "DocumentReference",
      id: SecureRandom.uuid,
      type: OpenStruct.new(
        coding: [
          OpenStruct.new(
            system: type_info[:system],
            code: type_info[:code],
            display: type_info[:display]
          )
        ],
        text: document_type.humanize
      ),
      content: [
        OpenStruct.new(
          attachment: OpenStruct.new(
            contentType: "application/pdf",
            title: filename,
            data: Base64.strict_encode64(pdf_data)
          )
        )
      ]
    )
  end
end
