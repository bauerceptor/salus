class Patient::TreatmentRequestsController < Patient::BaseController
  before_action :set_treatment_request, only: %i[show destroy]
  before_action :set_breadcrumbs

  def index
    @pagy, @treatment_requests = pagy(
      current_account.treatment_requests.order(requested_at: :desc)
    )
  end

  def show
    @treatment = Treatment.new if @treatment_request.approved?
  end

  def new
    @treatment_request = TreatmentRequest.new
  end

  def create
    @treatment_request = current_account.treatment_requests.build(treatment_request_params)

    if @treatment_request.save
      notify_specialist_request
      redirect_to patient_treatment_requests_path, notice: t(".success")
    else
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    unless @treatment_request.pending?
      redirect_to patient_treatment_requests_path, alert: t(".cannot_cancel")
      return
    end

    @treatment_request.destroy
    redirect_to patient_treatment_requests_path, notice: t(".success")
  end

  private

  def set_treatment_request
    @treatment_request = current_account.treatment_requests.find(params[:id])
  end

  def treatment_request_params
    params.expect(treatment_request: %i[title description start_date])
  end

  def notify_specialist_request
    specialist = current_account.user.specialist_patients.first&.specialist
    return unless specialist

    Notification.create!(
      account: specialist.account,
      title: "New Treatment Request",
      body: "#{current_account.full_name} is requesting approval for treatment: #{@treatment_request.title}",
      notification_type: "treatment_request"
    )
  end

  def set_breadcrumbs
    add_breadcrumb t("breadcrumbs.home"), authenticated_root_path
    add_breadcrumb t(".breadcrumbs.index"), patient_treatment_requests_path
  end
end
