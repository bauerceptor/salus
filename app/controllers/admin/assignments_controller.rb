class Admin::AssignmentsController < Admin::BaseController
  before_action :set_assignment, only: [:update]

  def index
    @filter = params[:filter] || "all"
    @specialist_id = params[:specialist_id]

    if @filter == "unassigned"
      @pagy, @accounts = pagy(unassigned_patients)
      @assignments = []
    else
      @pagy, @assignments = pagy(filtered_assignments)
      @accounts = []
    end

    @specialists = User.joins(:roles).where(roles: { name: "specialist" })
    @specialist_options = @specialists.map do |s|
      [s.email + (s.specialist ? " — #{s.specialist.specialization}" : ""), s.id]
    end
  end

  def create
    account = Account.find(params[:account_id])
    specialist_id = params[:specialist_id]

    if specialist_id.blank?
      redirect_to admin_assignments_path(filter: "unassigned"), alert: "Please select a specialist."
      return
    end

    specialist = User.find(specialist_id)
    unless specialist.specialist?
      redirect_to admin_assignments_path(filter: "unassigned"), alert: "Selected user is not a specialist."
      return
    end

    if SpecialistPatient.exists?(account_id: account.id, specialist_id: specialist_id)
      redirect_to admin_assignments_path(filter: "unassigned"), alert: "Patient is already assigned to this specialist."
      return
    end

    SpecialistPatient.create!(
      account_id: account.id,
      specialist_id: specialist_id,
      status: "active",
      relationship_type: "primary_care"
    )

    redirect_to admin_assignments_path(filter: "unassigned"), notice: "Patient assigned to specialist successfully."
  rescue ActiveRecord::RecordNotFound => e
    redirect_to admin_assignments_path(filter: "unassigned"), alert: "Account not found."
  rescue StandardError => e
    redirect_to admin_assignments_path(filter: "unassigned"), alert: "Failed to assign patient: #{e.message}"
  end

  def update
    if assignment_params[:specialist_id].blank?
      redirect_to admin_assignments_path, alert: "Please select a specialist."
      return
    end

    if @assignment.specialist_id == assignment_params[:specialist_id].to_s
      redirect_to admin_assignments_path, alert: "Patient is already assigned to this specialist."
      return
    end

    @assignment.update!(specialist_id: assignment_params[:specialist_id])
    redirect_to admin_assignments_path, notice: "Patient reassigned successfully."
  end

  def bulk_reassign
    if assignment_params[:specialist_id].blank?
      redirect_to admin_assignments_path, alert: "Please select a specialist."
      return
    end

    assignment_ids = params[:assignment_ids] || []
    if assignment_ids.empty?
      redirect_to admin_assignments_path, alert: "No patients selected."
      return
    end

    SpecialistPatient.where(id: assignment_ids).update_all(specialist_id: assignment_params[:specialist_id])

    flash[:notice] = "#{assignment_ids.size} patients reassigned."
    redirect_to admin_assignments_path
  end

  private

  def set_assignment
    @assignment = SpecialistPatient.find(params[:id])
  end

  def assignment_params
    params.expect(specialist: [:specialist_id]) if params[:specialist]
    params.permit(:specialist_id, :assignment_ids)
  end

  def filtered_assignments
    scope = SpecialistPatient.includes(account: :user, specialist: [:specialist])

    scope = scope.where(status: @filter) if @filter.present? && %w[active pending inactive].include?(@filter)
    scope = scope.where(specialist_id: @specialist_id) if @specialist_id.present?

    scope.order(created_at: :desc)
  end

  def unassigned_patients
    Account.where.not(id: SpecialistPatient.select(:account_id))
           .order(created_at: :desc)
  end
end
