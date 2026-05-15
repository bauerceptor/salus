require "rails_helper"

RSpec.describe "Patient::TreatmentRequests", type: :request do
  let(:user) { create(:user) }
  let(:account) { user.account }

  describe "GET #index" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get patient_treatment_requests_path
        expect(response).to be_successful
      end

      it "assigns treatment requests" do
        request = create(:treatment_request, account: account)
        get patient_treatment_requests_path
        expect(assigns(:treatment_requests)).to include(request)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get patient_treatment_requests_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "GET #new" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get new_patient_treatment_request_path
        expect(response).to be_successful
      end

      it "assigns a new treatment request" do
        get new_patient_treatment_request_path
        expect(assigns(:treatment_request)).to be_a_new(TreatmentRequest)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get new_patient_treatment_request_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        treatment_request: {
          title: "Chemotherapy",
          description: "Monthly chemotherapy sessions",
          start_date: 1.month.from_now
        }
      }
    end

    context "when authenticated with valid params" do
      before { sign_in user }

      it "creates a new treatment request" do
        expect do
          post patient_treatment_requests_path, params: valid_params
        end.to change(TreatmentRequest, :count).by(1)
      end

      it "redirects to index after creation" do
        post patient_treatment_requests_path, params: valid_params
        expect(response).to redirect_to(patient_treatment_requests_path)
      end

      it "sets status to pending" do
        post patient_treatment_requests_path, params: valid_params
        expect(assigns(:treatment_request).status).to eq("pending")
      end
    end

    context "when authenticated with invalid params" do
      before { sign_in user }

      it "does not create a new treatment request" do
        expect do
          post patient_treatment_requests_path, params: { treatment_request: { title: "" } }
        end.not_to change(TreatmentRequest, :count)
      end

      it "renders new template with error" do
        post patient_treatment_requests_path, params: { treatment_request: { title: "" } }
        expect(response).to render_template(:new)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post patient_treatment_requests_path, params: valid_params
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "GET #show" do
    let(:treatment_request) { create(:treatment_request, account: account) }

    context "when authenticated as owner" do
      before { sign_in user }

      it "returns a successful response" do
        get patient_treatment_request_path(id: treatment_request.id)
        expect(response).to be_successful
      end

      it "assigns the treatment request" do
        get patient_treatment_request_path(id: treatment_request.id)
        expect(assigns(:treatment_request)).to eq(treatment_request)
      end

      it "builds a new treatment when request is approved" do
        treatment_request.status = "approved"
        treatment_request.save
        get patient_treatment_request_path(id: treatment_request.id)
        expect(assigns(:treatment)).to be_a_new(Treatment)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get patient_treatment_request_path(id: treatment_request.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:treatment_request) { create(:treatment_request, account: account, status: "pending") }

    context "when authenticated as owner with pending request" do
      before { sign_in user }

      it "destroys the treatment request" do
        expect do
          delete patient_treatment_request_path(id: treatment_request.id)
        end.to change(TreatmentRequest, :count).by(-1)
      end

      it "redirects to index after destruction" do
        delete patient_treatment_request_path(id: treatment_request.id)
        expect(response).to redirect_to(patient_treatment_requests_path)
      end
    end

    context "when authenticated but request is not pending" do
      before { sign_in user }

      let!(:approved_request) { create(:treatment_request, account: account, status: "approved") }

      it "does not destroy the treatment request" do
        expect do
          delete patient_treatment_request_path(id: approved_request.id)
        end.not_to change(TreatmentRequest, :count)
      end

      it "redirects to index" do
        delete patient_treatment_request_path(id: approved_request.id)
        expect(response).to redirect_to(patient_treatment_requests_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete patient_treatment_request_path(id: treatment_request.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end
end
