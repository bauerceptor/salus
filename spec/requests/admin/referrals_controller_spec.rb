require "rails_helper"

RSpec.describe Admin::ReferralsController, type: :request do
  describe "GET /admin/referrals" do
    let(:admin) { create(:admin) }

    before do
      allow_any_instance_of(Admin::BaseController).to receive(:authenticate_admin!).and_return(true)
      allow_any_instance_of(Admin::BaseController).to receive(:admin_signed_in?).and_return(true)
      allow_any_instance_of(Admin::BaseController).to receive(:current_admin).and_return(admin)
    end

    it "returns a successful response" do
      get admin_referrals_path
      expect(response).to have_http_status(:success)
    end

    it "renders the admin dashboard layout" do
      get admin_referrals_path
      expect(response).to render_template layout: "admin_dashboard"
    end

    it "shows the Referrals page title" do
      get admin_referrals_path
      expect(response.body).to include("Referral Analytics")
    end

    context "with specialist referral data" do
      let(:specialist_request) { create(:specialist_request, status: "approved") }

      before do
        create(:specialist_referral_click, specialist_request: specialist_request, clicked_at: 1.day.ago)
        create(:specialist_referral_click, specialist_request: specialist_request, clicked_at: 2.days.ago)
      end

      it "shows specialist name in the referrals table" do
        get admin_referrals_path
        expect(response.body).to include(specialist_request.specialist.email)
      end

      it "shows click count per specialist" do
        get admin_referrals_path
        expect(response.body).to include("2")
      end

      it "shows the referral URL for each specialist" do
        get admin_referrals_path
        expect(response.body).to include(join_specialist_path(hash: specialist_request.hash_code))
      end

      it "shows a QR code for each referral URL" do
        get admin_referrals_path
        expect(response.body).to include("qr-code")
      end
    end

    context "conversion rates" do
      let!(:specialist_request) { create(:specialist_request, status: "approved") }
      let!(:patient_account) { create(:account) }

      it "shows conversion rate of 0% when no registrations completed" do
        get admin_referrals_path
        expect(response.body).to include("0%")
      end

      it "shows conversion rate when registrations are completed" do
        create_list(:specialist_referral_click, 5, specialist_request: specialist_request)
        create(:specialist_patient, specialist: specialist_request.specialist, account: patient_account)

        get admin_referrals_path
        expect(response.body).to include("100%")
      end
    end

    context "empty state" do
      it "shows empty state when no specialists have referral URLs" do
        get admin_referrals_path
        expect(response.body).to include("No referral data yet")
      end
    end

    context "sorted by clicks desc" do
      it "lists specialist with most clicks first" do
        sr1 = create(:specialist_request, status: "approved")
        sr2 = create(:specialist_request, status: "approved")
        create(:specialist_referral_click, specialist_request: sr1)
        create_list(:specialist_referral_click, 3, specialist_request: sr2)

        get admin_referrals_path
        body = response.body
        expect(body.index(sr2.specialist.email)).to be < body.index(sr1.specialist.email)
      end
    end

    context "authentication" do
      it "redirects unauthenticated requests to admin sign in" do
        allow_any_instance_of(Admin::BaseController).to receive(:authenticate_admin!).and_call_original
        allow_any_instance_of(Admin::BaseController).to receive(:admin_signed_in?).and_return(false)
        allow_any_instance_of(Admin::BaseController).to receive(:current_admin).and_return(nil)
        get admin_referrals_path
        expect(response).to redirect_to(admin_new_session_path)
      end
    end
  end
end
