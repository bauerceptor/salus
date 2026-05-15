require "rails_helper"

RSpec.describe "Settings::Privacy", type: :request do
  let(:user) { create(:user) }
  let(:account) { user.account }

  describe "GET #show" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get settings_privacy_path
        expect(response).to be_successful
      end

      it "assigns @privacy_settings" do
        get settings_privacy_path
        expect(assigns(:privacy_settings)).to be_present
      end

      it "renders show template" do
        get settings_privacy_path
        expect(response).to render_template(:show)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get settings_privacy_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "PATCH #update" do
    let(:valid_params) do
      {
        privacy: {
          profile_visibility: "friends",
          show_health_data: "false",
          allow_friend_requests: "true",
          show_online_status: "false",
          share_measurements: "false"
        }
      }
    end

    context "when authenticated with valid params" do
      before { sign_in user }

      it "updates privacy settings" do
        patch settings_privacy_path, params: valid_params
        account.reload
        expect(account.privacy_settings["profile_visibility"]).to eq("friends")
      end

      it "redirects to show after update" do
        patch settings_privacy_path, params: valid_params
        expect(response).to redirect_to(settings_privacy_path)
      end

      it "shows success notice" do
        patch settings_privacy_path, params: valid_params
        expect(flash[:notice]).to eq(I18n.t("settings.privacy.update.success"))
      end
    end

    context "when authenticated with invalid params" do
      before { sign_in user }

      it "renders show with error" do
        patch settings_privacy_path, params: { privacy: { profile_visibility: "invalid" } }
        expect(response).to render_template(:show)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch settings_privacy_path, params: valid_params
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end
end
