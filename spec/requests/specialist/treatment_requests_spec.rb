require "rails_helper"

RSpec.describe "Specialist::TreatmentRequests", type: :request do
  let(:specialist_user) { create(:user, :specialist) }
  let(:patient_user) { create(:user) }
  let(:patient_account) { patient_user.account }

  before do
    create(:specialist_patient, specialist: specialist_user, account: patient_account, status: "active")
  end

  describe "GET #index" do
    context "when authenticated as specialist" do
      before { sign_in specialist_user }

      it "returns a successful response" do
        get specialist_treatment_requests_path
        expect(response).to be_successful
      end

      it "assigns pending treatment requests for my patients" do
        request = create(:treatment_request, account: patient_account, status: "pending")
        get specialist_treatment_requests_path
        expect(assigns(:treatment_requests)).to include(request)
      end

      it "does not include approved requests" do
        approved_request = create(:treatment_request, account: patient_account, status: "approved")
        get specialist_treatment_requests_path
        expect(assigns(:treatment_requests)).not_to include(approved_request)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get specialist_treatment_requests_path
        expect(response).to redirect_to(specialist_new_session_path)
      end
    end

    context "when authenticated as regular patient" do
      before { sign_in patient_user }

      it "denies access" do
        get specialist_treatment_requests_path
        expect(response).not_to be_successful
      end
    end
  end

  describe "GET #show" do
    let(:treatment_request) { create(:treatment_request, account: patient_account, status: "pending") }

    context "when authenticated as specialist" do
      before { sign_in specialist_user }

      it "returns a successful response" do
        get specialist_treatment_request_path(id: treatment_request.id)
        expect(response).to be_successful
      end

      it "assigns the treatment request" do
        get specialist_treatment_request_path(id: treatment_request.id)
        expect(assigns(:treatment_request)).to eq(treatment_request)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get specialist_treatment_request_path(id: treatment_request.id)
        expect(response).to redirect_to(specialist_new_session_path)
      end
    end
  end

  describe "PATCH #update - approve" do
    let(:treatment_request) { create(:treatment_request, account: patient_account, status: "pending") }

    context "when authenticated as specialist" do
      before { sign_in specialist_user }

      it "approves the treatment request" do
        patch specialist_treatment_request_path(id: treatment_request.id, status: "approved")
        treatment_request.reload
        expect(treatment_request.status).to eq("approved")
      end

      it "creates a Treatment from the request" do
        expect do
          patch specialist_treatment_request_path(id: treatment_request.id, status: "approved")
        end.to change(Treatment, :count).by(1)
      end

      it "notifies the patient" do
        expect do
          patch specialist_treatment_request_path(id: treatment_request.id, status: "approved")
        end.to change(Notification, :count).by(1)
      end

      it "redirects to index after approval" do
        patch specialist_treatment_request_path(id: treatment_request.id, status: "approved")
        expect(response).to redirect_to(specialist_treatment_requests_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch specialist_treatment_request_path(id: treatment_request.id, status: "approved")
        expect(response).to redirect_to(specialist_new_session_path)
      end
    end
  end

  describe "PATCH #update - reject" do
    let(:treatment_request) { create(:treatment_request, account: patient_account, status: "pending") }

    context "when authenticated as specialist" do
      before { sign_in specialist_user }

      it "rejects the treatment request" do
        patch specialist_treatment_request_path(id: treatment_request.id, status: "rejected", reason: "Not suitable")
        treatment_request.reload
        expect(treatment_request.status).to eq("rejected")
      end

      it "stores the rejection reason" do
        patch specialist_treatment_request_path(id: treatment_request.id, status: "rejected", reason: "Too expensive")
        treatment_request.reload
        expect(treatment_request.rejection_reason).to eq("Too expensive")
      end

      it "redirects to index after rejection" do
        patch specialist_treatment_request_path(id: treatment_request.id, status: "rejected")
        expect(response).to redirect_to(specialist_treatment_requests_path)
      end

      it "does not create a Treatment" do
        expect do
          patch specialist_treatment_request_path(id: treatment_request.id, status: "rejected")
        end.not_to change(Treatment, :count)
      end
    end

    context "with invalid status" do
      before { sign_in specialist_user }

      it "redirects back with alert" do
        patch specialist_treatment_request_path(id: treatment_request.id, status: "invalid", locale: I18n.locale)
        expect(response).to redirect_to(specialist_treatment_request_path(id: treatment_request.id,
                                                                          locale: I18n.locale))
        expect(flash[:alert]).to be_present
      end
    end
  end
end
