require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  describe "GET /admin/dashboard" do
    context "when admin is authenticated" do
      let(:admin) { create(:admin) }

      before do
        # Stub authenticate_admin! to prevent redirect to sign_in
        allow_any_instance_of(Admin::BaseController).to receive(:authenticate_admin!).and_return(true)
        # Stub admin_signed_in? to return true
        allow_any_instance_of(Admin::BaseController).to receive(:admin_signed_in?).and_return(true)
        # Stub current_admin to return our admin
        allow_any_instance_of(Admin::BaseController).to receive(:current_admin).and_return(admin)
      end

      it "returns a successful response" do
        get admin_dashboard_path
        expect(response).to have_http_status(:success)
      end

      it "renders the admin dashboard layout" do
        get admin_dashboard_path
        expect(response).to render_template layout: "admin_dashboard"
      end

      it "shows the command center page title" do
        get admin_dashboard_path
        expect(response.body).to include("Command Center")
      end

      it "shows total patients stat card with count" do
        create_list(:account, 5)
        get admin_dashboard_path
        expect(response.body).to include("5")
        expect(response.body).to include("Total Patients")
      end

      it "shows assigned patients stat card with count" do
        account = create(:account)
        specialist_user = create(:user, :specialist)
        create(:specialist_patient, account: account, specialist: specialist_user, status: "active")

        get admin_dashboard_path
        expect(response.body).to match(/1.*Assigned to Specialist|Assigned to Specialist.*1/m)
      end

      it "shows unassigned patients stat card with count" do
        create_list(:account, 3)

        get admin_dashboard_path
        expect(response.body).to include("3")
        expect(response.body).to include("Unassigned")
      end

      it "shows pending specialist requests stat card with count" do
        create(:specialist_request, status: "pending")
        create(:specialist_request, status: "pending")

        get admin_dashboard_path
        expect(response.body).to include("2")
        expect(response.body).to include("Pending Requests")
      end

      it "shows active specialists stat card with count" do
        create(:user, :specialist)
        create(:user, :specialist)

        get admin_dashboard_path
        expect(response.body).to include("2")
        expect(response.body).to include("Active Specialists")
      end

      it "unassigned stat card links to assignments filter" do
        get admin_dashboard_path
        expect(response.body).to include('href="/admin/assignments?filter=unassigned"')
      end

      it "pending requests stat card links to specialist requests" do
        get admin_dashboard_path
        expect(response.body).to include('href="/admin/specialist_requests"')
      end

      it "active specialists stat card links to specialists list" do
        get admin_dashboard_path
        expect(response.body).to include('href="/admin/specialists"')
      end

      it "dashboard uses admin_dashboard layout not application layout" do
        get admin_dashboard_path
        expect(response).to render_template(layout: "admin_dashboard")
      end

      it "dashboard has sidebar navigation" do
        get admin_dashboard_path
        expect(response.body).to include("Dashboard")
        expect(response.body).to include("Specialists")
        expect(response.body).to include("Assignments")
      end

      it "zero unassigned shows 0 not error" do
        get admin_dashboard_path
        expect(response.body).to include("0")
        expect(response.body).not_to include("error", "Error")
      end
    end

    context "when admin is not authenticated" do
      it "redirects to admin sign in" do
        get admin_dashboard_path
        expect(response).to redirect_to admin_new_session_path
      end
    end
  end
end
