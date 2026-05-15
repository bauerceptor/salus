require "rails_helper"

RSpec.describe NotificationsController, type: :request do
  let(:user) { create(:user) }
  let(:account) { user.account }

  describe "GET #index" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get notifications_path
        expect(response).to be_successful
      end

      it "assigns @notifications" do
        notification = create(:notification, account: account)
        get notifications_path
        expect(assigns(:notifications)).to include(notification)
      end

      it "paginates notifications" do
        create_list(:notification, 25, account: account)
        get notifications_path
        expect(assigns(:pagy)).to be_present
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get notifications_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "GET #show" do
    let!(:notification) { create(:notification, account: account) }

    context "when authenticated" do
      before { sign_in user }

      it "marks notification as read" do
        get notification_path(id: notification.id)
        notification.reload
        expect(notification.read_at).to be_present
      end

      it "returns json" do
        get notification_path(id: notification.id)
        expect(response.media_type).to eq("application/json")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get notification_path(id: notification.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "PATCH #update" do
    let!(:notification) { create(:notification, account: account, read_at: nil) }

    context "when authenticated" do
      before { sign_in user }

      it "marks notification as read" do
        patch notification_path(id: notification.id)
        notification.reload
        expect(notification.read_at).to be_present
      end

      it "redirects to notifications path" do
        patch notification_path(id: notification.id)
        expect(response).to redirect_to(notifications_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch notification_path(id: notification.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:notification) { create(:notification, account: account) }

    context "when authenticated" do
      before { sign_in user }

      it "destroys the notification" do
        expect do
          delete notification_path(id: notification.id)
        end.to change(Notification, :count).by(-1)
      end

      it "redirects to notifications path" do
        delete notification_path(id: notification.id)
        expect(response).to redirect_to(notifications_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete notification_path(id: notification.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "POST #mark_all_read" do
    let!(:notification1) { create(:notification, account: account, read_at: nil) }
    let!(:notification2) { create(:notification, account: account, read_at: nil) }

    context "when authenticated" do
      before { sign_in user }

      it "marks all notifications as read" do
        post mark_all_read_notifications_path
        notification1.reload
        notification2.reload
        expect(notification1.read_at).to be_present
        expect(notification2.read_at).to be_present
      end

      it "redirects to notifications path" do
        post mark_all_read_notifications_path
        expect(response).to redirect_to(notifications_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post mark_all_read_notifications_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end
end
