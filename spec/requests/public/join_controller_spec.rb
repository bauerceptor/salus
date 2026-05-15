require "rails_helper"

RSpec.describe Public::JoinController, type: :request do
  describe "GET /join/specialist/:hash" do
    let(:specialist_request) { create(:specialist_request) }

    it "returns a successful response for a valid hash" do
      get join_specialist_path(hash: specialist_request.hash_code)
      expect(response).to have_http_status(:success)
    end

    it "renders the specialist join page" do
      get join_specialist_path(hash: specialist_request.hash_code)
      expect(response).to render_template("specialist")
    end

    it "shows the specialist's name on the page" do
      get join_specialist_path(hash: specialist_request.hash_code)
      expect(response.body).to include(specialist_request.account.full_name)
    end

    it "shows the specialist's specialization" do
      get join_specialist_path(hash: specialist_request.hash_code)
      specialization = specialist_request.specialist.specialist&.specialization || specialist_request.specialist.email
      expect(response.body).to include(specialization)
    end

    context "when hash is invalid" do
      it "returns a 404 for an unknown hash" do
        get join_specialist_path(hash: "INVALIDHASH")
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when specialist request is rejected" do
      let(:rejected_request) { create(:specialist_request, status: "rejected") }

      it "returns a 404 for a rejected specialist request" do
        get join_specialist_path(hash: rejected_request.hash_code)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when specialist request is pending" do
      let(:pending_request) { create(:specialist_request, status: "pending") }

      it "shows the specialist info for pending requests" do
        get join_specialist_path(hash: pending_request.hash_code)
        expect(response.body).to include(pending_request.account.full_name)
      end
    end
  end

  describe "POST /join/specialist/:hash (request to join)" do
    let(:specialist_request) { create(:specialist_request, status: "approved") }
    let(:patient_account) { create(:account) }

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(patient_account)
      allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(true)
    end

    it "creates a pending SpecialistPatient when logged-in patient requests to join" do
      post join_specialist_path(hash: specialist_request.hash_code)
      sp = SpecialistPatient.last
      expect(sp.account).to eq(patient_account)
      expect(sp.specialist).to eq(specialist_request.specialist)
      expect(sp.status).to eq("pending")
      expect(sp.relationship_type).to eq("primary_care")
    end

    it "creates a SpecialistReferralClick when visiting the URL (GET, not POST)" do
      get join_specialist_path(hash: specialist_request.hash_code)
      # GET creates the click
      expect(SpecialistReferralClick.count).to eq(1)
      # POST does NOT create an additional click
      post join_specialist_path(hash: specialist_request.hash_code)
      expect(SpecialistReferralClick.count).to eq(1)
    end

    it "redirects to sign-in if no account is logged in" do
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(nil)
      allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(false)
      post join_specialist_path(hash: specialist_request.hash_code)
      expect(response).to redirect_to(auth_new_session_path(locale: I18n.locale))
    end

    it "shows already associated message if patient already has active assignment" do
      create(:specialist_patient, account: patient_account, specialist: specialist_request.specialist,
                                  status: "active")
      post join_specialist_path(hash: specialist_request.hash_code)
      follow_redirect!
      expect(response.body).to include("already associated")
    end

    it "records click when GET is called before POST" do
      # Initially no clicks
      expect(SpecialistReferralClick.count).to eq(0)
      # GET creates a click
      get join_specialist_path(hash: specialist_request.hash_code)
      expect(SpecialistReferralClick.count).to eq(1)
      # POST does not create additional click (only GET creates)
      post join_specialist_path(hash: specialist_request.hash_code)
      expect(SpecialistReferralClick.count).to eq(1)
    end

    context "when hash is invalid" do
      it "returns 404 on POST with invalid hash" do
        post join_specialist_path(hash: "BADHASH")
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
