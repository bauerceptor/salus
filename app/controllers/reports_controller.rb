class ReportsController < BaseController
  def patient_profile
    respond_to do |format|
      format.pdf do
        pdf_service = Reports::GeneratePatientProfileService.new(current_account)
        pdf_content = pdf_service.call

        send_data pdf_content,
                  filename: "patient_profile_#{current_account.id}_#{Time.zone.today.iso8601}.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end
end
