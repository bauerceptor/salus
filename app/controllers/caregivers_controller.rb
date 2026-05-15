class CaregiversController < BaseController
  before_action :set_caregiver, only: %i[show update destroy accept reject]

  def index
    @pagy, @caregivers = pagy(current_account.caregivers.accepted)
  end

  def pending
    @pagy, @pending_requests = pagy(current_account.caregivers.pending)
  end

  def show
    @patient = @caregiver.account
    @caregiver_account = @caregiver.caregiver_account
  end

  def new
    @caregiver = Caregiver.new
    @potential_caregivers = potential_caregivers
  end

  def create
    @caregiver = current_account.caregivers.build(caregiver_params)

    respond_to do |format|
      if @caregiver.save
        format.html { redirect_to caregivers_path, notice: t(".success") }
      else
        @potential_caregivers = potential_caregivers
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  def update
    respond_to do |format|
      if @caregiver.update(caregiver_params)
        format.html { redirect_to caregiver_path(id: @caregiver.id, locale: I18n.locale), notice: t(".success") }
      else
        format.html { render :edit, status: :unprocessable_content }
      end
    end
  end

  def destroy
    @caregiver.destroy

    respond_to do |format|
      format.html { redirect_to caregivers_path, notice: t(".success") }
    end
  end

  def accept
    @caregiver.accept

    respond_to do |format|
      format.html { redirect_to pending_caregivers_path, notice: t(".success") }
    end
  end

  def reject
    @caregiver.destroy

    respond_to do |format|
      format.html { redirect_to pending_caregivers_path, notice: t(".destroy.success") }
    end
  end

  def requests_received
    @pagy, @requests = pagy(
      current_account.caregivers_as_caregiver.pending.where(is_accepted: false)
    )
  end

  def accept_request
    @caregiver = Caregiver.find(params[:id])
    @caregiver.accept

    respond_to do |format|
      format.html { redirect_to requests_received_caregivers_path, notice: t(".success") }
    end
  end

  def reject_request
    @caregiver = Caregiver.find(params[:id])
    @caregiver.destroy

    respond_to do |format|
      format.html { redirect_to requests_received_caregivers_path, notice: t(".destroy.success") }
    end
  end

  private

  def set_caregiver
    @caregiver = current_account.caregivers.find(params[:id])
  end

  def caregiver_params
    params.expect(
      caregiver: %i[caregiver_account_id relationship
                    can_view_medications can_view_measurements can_view_diseases
                    notify_on_missed_dose notify_on_low_adherence notify_on_abnormal_measurement]
    )
  end

  def potential_caregivers
    Account.where.not(id: current_account.id)
           .where.not(id: current_account.caregivers.pluck(:caregiver_account_id))
  end
end
