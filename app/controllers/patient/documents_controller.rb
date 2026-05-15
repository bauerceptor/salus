class Patient::DocumentsController < Patient::BaseController
  def index
    @documents = ClinicalDocument.for_account(current_user.account).order(created_at: :desc)
  end

  def show
    document = ClinicalDocument.find(params[:id])

    if document.account_id != current_user.account_id
      head :forbidden
      return
    end

    content = document.file_data["content"]
    pdf_data = Base64.decode64(content)

    send_data pdf_data, type: document.file_data["content_type"] || "application/pdf", disposition: "inline"
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end
end