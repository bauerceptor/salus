require "rails_helper"

RSpec.describe Admin::SpecialistRequestsController, type: :request do
  describe "Authentication" do
    context "when admin is NOT authenticated" do
      it "redirects to admin sign in" do
        get admin_specialist_requests_path
        expect(response).to redirect_to(admin_new_session_path)
      end
    end
  end

  describe "GET /admin/specialist_requests" do
    let(:admin) { create(:admin) }

    before do
      allow_any_instance_of(Admin::BaseController).to receive(:authenticate_admin!).and_return(true)
      allow_any_instance_of(Admin::BaseController).to receive(:admin_signed_in?).and_return(true)
      allow_any_instance_of(Admin::BaseController).to receive(:current_admin).and_return(admin)
    end

    it "returns successful response" do
      get admin_specialist_requests_path
      expect(response).to have_http_status(:success)
    end

    it "renders admin dashboard layout" do
      get admin_specialist_requests_path
      expect(response).to render_template layout: "admin_dashboard"
    end

    context "with pending specialist requests" do
      let(:specialist_user) { create(:user, :specialist) }
      let!(:pending_req) { create(:specialist_request, specialist: specialist_user, status: "pending") }

      it "shows pending specialist requests" do
        get admin_specialist_requests_path
        expect(response.body).to include(pending_req.specialist.account.full_name)
        expect(response.body).to include(pending_req.specialist.specialist.specialization)
      end

      it "shows days pending for each request" do
        pending_req.update!(created_at: 3.days.ago)
        get admin_specialist_requests_path
        expect(response.body).to include("3 days")
      end

      it "has approve and reject buttons" do
        get admin_specialist_requests_path
        expect(response.body).to include("Approve")
        expect(response.body).to include("Reject")
      end
    end

    it "shows empty state when no pending requests" do
      get admin_specialist_requests_path
      expect(response.body).to include("No pending specialist requests")
    end
  end

  describe "POST /admin/specialist_requests/:id/approve" do
    let(:admin) { create(:admin) }
    let(:specialist_user) { create(:user, :specialist) }
    let!(:specialist_request) { create(:specialist_request, specialist: specialist_user, status: "pending") }

    before do
      allow_any_instance_of(Admin::BaseController).to receive(:authenticate_admin!).and_return(true)
      allow_any_instance_of(Admin::BaseController).to receive(:admin_signed_in?).and_return(true)
      allow_any_instance_of(Admin::BaseController).to receive(:current_admin).and_return(admin)
    end

    it "approves the specialist request" do
      post approve_admin_specialist_request_path(id: specialist_request.id)
      expect(specialist_request.reload.status).to eq("approved")
    end

    it "creates a SpecialistPatient linking patient to specialist" do
      expect do
        post approve_admin_specialist_request_path(id: specialist_request.id)
      end.to change(SpecialistPatient, :count).by(1)

      sp = SpecialistPatient.last
      expect(sp.account_id).to eq(specialist_request.account_id)
      expect(sp.specialist_id).to eq(specialist_request.specialist_id)
      expect(sp.status).to eq("active")
      expect(sp.relationship_type).to eq("primary_care")
    end

    it "redirects to admin specialist requests index with notice" do
      post approve_admin_specialist_request_path(id: specialist_request.id)
      expect(response).to redirect_to(admin_specialist_requests_path)
      expect(flash[:notice]).to eq("Specialist request approved successfully.")
    end

    context "when already approved" do
      before { specialist_request.update!(status: "approved") }

      it "handles already approved request gracefully" do
        expect do
          post approve_admin_specialist_request_path(id: specialist_request.id)
        end.not_to change(SpecialistPatient, :count)
      end
    end
  end

  describe "POST /admin/specialist_requests/:id/reject" do
    let(:admin) { create(:admin) }
    let(:specialist_user) { create(:user, :specialist) }
    let!(:specialist_request) { create(:specialist_request, specialist: specialist_user, status: "pending") }

    before do
      allow_any_instance_of(Admin::BaseController).to receive(:authenticate_admin!).and_return(true)
      allow_any_instance_of(Admin::BaseController).to receive(:admin_signed_in?).and_return(true)
      allow_any_instance_of(Admin::BaseController).to receive(:current_admin).and_return(admin)
    end

    it "rejects the specialist request" do
      post reject_admin_specialist_request_path(id: specialist_request.id)
      expect(specialist_request.reload.status).to eq("rejected")
    end

    it "does not create a SpecialistPatient when rejecting" do
      expect do
        post reject_admin_specialist_request_path(id: specialist_request.id)
      end.not_to change(SpecialistPatient, :count)
    end

    it "redirects to admin specialist requests index with notice" do
      post reject_admin_specialist_request_path(id: specialist_request.id)
      expect(response).to redirect_to(admin_specialist_requests_path)
      expect(flash[:notice]).to eq("Specialist request rejected.")
    end

    it "handles already rejected request gracefully" do
      specialist_request.update!(status: "rejected")
      post reject_admin_specialist_request_path(id: specialist_request.id)
      expect(specialist_request.reload.status).to eq("rejected")
    end
  end

  describe "GET /admin/specialist_requests/:id" do
    let(:admin) { create(:admin) }
    let(:specialist_user) { create(:user, :specialist) }
    let!(:specialist_request) { create(:specialist_request, specialist: specialist_user, status: "pending") }

    before do
      allow_any_instance_of(Admin::BaseController).to receive(:authenticate_admin!).and_return(true)
      allow_any_instance_of(Admin::BaseController).to receive(:admin_signed_in?).and_return(true)
      allow_any_instance_of(Admin::BaseController).to receive(:current_admin).and_return(admin)
    end

    it "returns successful response" do
      get admin_specialist_request_path(id: specialist_request.id)
      expect(response).to have_http_status(:success)
    end

    it "shows full applicant details" do
      get admin_specialist_request_path(id: specialist_request.id)
      expect(response.body).to include(specialist_request.specialist.account.full_name)
      expect(response.body).to include(specialist_request.specialist.specialist.specialization)
    end

    it "has approve and reject actions" do
      get admin_specialist_request_path(id: specialist_request.id)
      expect(response.body).to include("Approve")
      expect(response.body).to include("Reject")
    end
  end
end
