class ClinicalDocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_specialist!, except: [:show]

  def index
    @patient = Account.find(params[:patient_id])
    current_user.specialist_patients.find_by!(account: @patient)

    @documents = ClinicalDocument.for_account(@patient).order(created_at: :desc)
  end

  def create
    @patient = Account.find(params[:patient_id])
    current_user.specialist_patients.find_by!(account: @patient)

    document = ClinicalDocument.new(
      account: @patient,
      uploaded_by: current_user,
      document_type: document_params[:document_type],
      file_data: document_params[:file_data]
    )

    if document.save
      ClinicalDocumentProcessingJob.perform_later(document.id) if document_params[:auto_process] == "true"

      redirect_to clinical_documents_path(patient_id: @patient.id), notice: "Document uploaded successfully."
    else
      redirect_to clinical_documents_path(patient_id: @patient.id), alert: "Failed to upload document."
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def show
    document = ClinicalDocument.find(params[:id])
    @patient = document.account

    if current_user.specialist?
      current_user.specialist_patients.find_by!(account: @patient)
    elsif document.account_id != current_user.account_id
      head :forbidden
      return
    end

    content = document.file_data["content"]
    pdf_data = Base64.decode64(content)

    respond_to do |format|
      format.html
      format.pdf do
        send_data pdf_data, type: document.file_data["content_type"] || "application/pdf", disposition: "inline"
      end
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def destroy
    document = ClinicalDocument.find(params[:id])
    @patient = document.account

    current_user.specialist_patients.find_by!(account: @patient)

    document.destroy
    redirect_to clinical_documents_path(patient_id: @patient.id), notice: "Document deleted."
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  private

  def document_params
    params.expect(clinical_document: [:document_type, :auto_process, { file_data: {} }])
  end

  def ensure_specialist!
    return if current_user.specialist?

    redirect_to authenticated_root_path, alert: "Access denied. Specialists only."
  end
end
