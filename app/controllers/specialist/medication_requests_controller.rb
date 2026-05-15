class Specialist::MedicationRequestsController < Specialist::BaseController
  def index
    @pagy, @medication_requests = pagy(
      MedicationRequest.pending
                        .joins(:account)
                        .where(accounts: { id: current_user.specialist_patients.active.select(:account_id) })
                        .order(requested_at: :desc)
    )
  end

  def update
    @medication_request = MedicationRequest.find(params[:id])

    unless current_user.specialist_patients.active.exists?(account: @medication_request.account)
      raise ActiveRecord::RecordNotFound
    end

    if @medication_request.pending?
      if params[:status] == "approved"
        @medication_request.approve!
        create_medication_from_request!
        redirect_to specialist_medication_requests_path, notice: "Medication request approved."
      elsif params[:status] == "rejected"
        @medication_request.reject!
        redirect_to specialist_medication_requests_path, notice: "Medication request rejected."
      else
        redirect_to specialist_medication_requests_path, alert: "Invalid status."
      end
    else
      redirect_to specialist_medication_requests_path, alert: "Request has already been resolved."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to specialist_medication_requests_path, alert: "Request not found."
  end

  private

  def create_medication_from_request!
    Medication.create!(
      account: @medication_request.account,
      name: @medication_request.medication_name,
      dosage: @medication_request.dosage.presence || "Not specified",
      frequency: @medication_request.frequency.presence || "Not specified",
      is_active: true,
      source: "patient_request",
      medication_request_id: @medication_request.id
    )
  end
end
