class Specialist::TreatmentRequestsController < Specialist::BaseController
  before_action :set_treatment_request, only: %i[show update]
  before_action :set_breadcrumbs

  def index
    @tab = %w[patient_requests doctor_prescriptions].include?(params[:tab]) ? params[:tab] : "patient_requests"

    pending_scope = TreatmentRequest.pending
                                    .joins(:account)
                                    .where(accounts: { id: current_user.specialist_patients.active.select(:account_id) })

    if @tab == "patient_requests"
      @pending_requests_count = pending_scope.count
      @pagy, @treatment_requests = pagy(pending_scope.order(requested_at: :desc))
    else
      @pending_requests_count = 0
      @pagy, @prescriptions = pagy(
        current_user.specialist_recommendations
                    .where(recommendation_type: "treatment")
                    .order(created_at: :desc)
      )
    end
  end

  def show; end

  def update
    if params[:status] == "approved"
      @treatment_request.approve!(current_user)
      create_treatment_from_request
      redirect_to specialist_treatment_requests_path, notice: t(".approved")
    elsif params[:status] == "rejected"
      @treatment_request.reject!(current_user, params[:reason])
      redirect_to specialist_treatment_requests_path, notice: t(".rejected")
    else
      redirect_to specialist_treatment_request_path(id: @treatment_request.id, locale: I18n.locale),
                  alert: t(".invalid_status")
    end
  end

  private

  def set_treatment_request
    @treatment_request = TreatmentRequest.find(params[:id])
  end

  def set_breadcrumbs
    add_breadcrumb t("breadcrumbs.home"), specialist_dashboard_path
    add_breadcrumb t(".breadcrumbs.index"), specialist_treatment_requests_path
  end

  def create_treatment_from_request
    Treatment.create!(
      account: @treatment_request.account,
      title: @treatment_request.title,
      name: @treatment_request.title,
      description: @treatment_request.description,
      start_date: @treatment_request.start_date,
      approval_status: "approved",
      approved_by_id: current_user.id,
      approved_at: Time.current,
      source: "patient_request",
      effectiveness: 3
    )

    Notification.create!(
      account: @treatment_request.account,
      title: "Treatment Approved",
      body: "Your treatment request '#{@treatment_request.title}' has been approved by Dr. #{current_user.account.full_name}",
      notification_type: "treatment_approved"
    )
  end
end
