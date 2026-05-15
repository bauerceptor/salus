require "rails_helper"

RSpec.describe Admin::ChatHealthController, type: :request do
  describe "Authentication" do
    context "when admin is NOT authenticated" do
      it "redirects to admin sign in" do
        get admin_chat_health_path
        expect(response).to redirect_to(admin_new_session_path)
      end
    end
  end

  describe "GET /admin/chat_health" do
    let(:admin) { create(:admin) }

    before do
      allow_any_instance_of(Admin::BaseController).to receive(:authenticate_admin!).and_return(true)
      allow_any_instance_of(Admin::BaseController).to receive(:admin_signed_in?).and_return(true)
      allow_any_instance_of(Admin::BaseController).to receive(:current_admin).and_return(admin)
    end

    it "returns a successful response" do
      get admin_chat_health_path
      expect(response).to have_http_status(:success)
    end

    it "renders the admin dashboard layout" do
      get admin_chat_health_path
      expect(response).to render_template layout: "admin_dashboard"
    end

    it "renders chat health index template" do
      get admin_chat_health_path
      expect(response).to render_template("index")
    end

    it "shows Chat Health page title" do
      get admin_chat_health_path
      expect(response.body).to include("Chat Health Monitor")
    end

    it "shows specialist health cards" do
      specialist_user = create(:user, :specialist)
      specialist_user.reload

      get admin_chat_health_path
      expect(response.body).to include(specialist_user.account.full_name)
    end

    it "shows empty state when no specialists exist" do
      allow(Admin::ChatHealthService).to receive(:new).and_return(
        double("service", health_stats: [])
      )

      get admin_chat_health_path
      expect(response.body).to include("No specialists found")
    end

    it "shows messages count per specialist" do
      specialist_user = create(:user, :specialist)
      specialist_user.reload
      create_list(:specialist_message, 3, specialist: specialist_user, sender_type: "specialist")

      get admin_chat_health_path
      expect(response.body).to include("3")
    end

    it "shows zero history patients count" do
      specialist_user = create(:user, :specialist)
      specialist_user.reload

      fake_stats = [
        {
          specialist_id: specialist_user.id,
          specialist_name: specialist_user.account.full_name,
          specialization: specialist_user.specialist.specialization,
          messages_sent_last_30d: 0,
          zero_history_patients: 1,
          last_message_at: nil
        }
      ]
      allow(Admin::ChatHealthService).to receive(:new).and_return(
        double("service", health_stats: fake_stats)
      )

      get admin_chat_health_path
      expect(response.body).to include("1")
      expect(response.body).to include("1 patient(s) with no chat history")
    end

    it "shows last message time or 'No messages' indicator" do
      specialist_user = create(:user, :specialist)
      specialist_user.reload
      create(:specialist_message, specialist: specialist_user, sender_type: "specialist", created_at: 2.days.ago)

      get admin_chat_health_path
      expect(response.body).to include("2 days ago")
    end
  end
end
