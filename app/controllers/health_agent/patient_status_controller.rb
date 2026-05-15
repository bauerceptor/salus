module HealthAgent
  class PatientStatusController < BaseController
    def show
      patient = Account.find(params[:patient_id])
      service = HealthAlertService.new(account: patient, specialist: current_specialist)
      summary = service.query_patient_status

      render json: { status: summary }
    end
  end
end
