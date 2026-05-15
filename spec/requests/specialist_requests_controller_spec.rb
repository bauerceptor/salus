require "rails_helper"

RSpec.describe SpecialistRequestsController, type: :request do
  let(:user) { create(:user) }
  let(:account) { user.account }

  describe "GET #index" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get specialist_requests_path
        expect(response).to be_successful
      end

      it "assigns @specialist_requests" do
        request = create(:specialist_request, account: account)
        get specialist_requests_path
        expect(assigns(:specialist_requests)).to include(request)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get specialist_requests_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "GET #new" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get new_specialist_request_path
        expect(response).to be_successful
      end

      it "assigns @specialist_request" do
        get new_specialist_request_path
        expect(assigns(:specialist_request)).to be_a_new(SpecialistRequest)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get new_specialist_request_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "POST #create" do
    let(:specialist_user) { create(:user, :specialist) }
    let(:valid_params) do
      {
        specialist_request: {
          field_of_expertise: "Cardiology",
          specialization: "Heart Specialist",
          specialization_description: "Board certified cardiologist with 10 years experience",
          message: "I would like to become a specialist"
        }
      }
    end

    context "when authenticated with valid params" do
      before { sign_in user }

      it "creates a new specialist request" do
        expect do
          post specialist_requests_path, params: valid_params
        end.to change(SpecialistRequest, :count).by(1)
      end

      it "redirects to specialist requests path" do
        post specialist_requests_path, params: valid_params
        expect(response).to redirect_to(specialist_requests_path)
      end
    end

    context "when authenticated with invalid params" do
      before { sign_in user }

      it "does not create a new specialist request" do
        expect do
          post specialist_requests_path, params: { specialist_request: { field_of_expertise: "", specialization: "", specialization_description: "", message: "" } }
        end.not_to change(SpecialistRequest, :count)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post specialist_requests_path, params: valid_params
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end
end
