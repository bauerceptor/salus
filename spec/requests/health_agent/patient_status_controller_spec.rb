require "rails_helper"

RSpec.describe HealthAgent::PatientStatusController, type: :request do
  describe "GET #show" do
    context "when not authenticated" do
      it "redirects to login" do
        get health_agent_patient_status_path(patient_id: "some-id")
        expect(response).to have_http_status(:found)
        expect(response.redirect_url).to include("/specialist/sign_in")
      end
    end
  end
end
