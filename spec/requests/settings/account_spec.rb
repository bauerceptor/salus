require "rails_helper"

RSpec.describe "Settings::Account", type: :request do
  let(:user) { create(:user) }
  let(:account) { user.account }

  describe "GET #show" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get settings_account_path
        expect(response).to be_successful
      end

      it "assigns @account" do
        get settings_account_path
        expect(assigns(:account)).to eq(account)
      end

      it "assigns @education_options" do
        get settings_account_path
        expect(assigns(:education_options)).to be_present
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get settings_account_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "PATCH #update" do
    let(:valid_params) do
      {
        account: {
          first_name: "John",
          last_name: "Doe",
          country: "USA",
          city: "New York"
        }
      }
    end

    context "when authenticated with valid params" do
      before { sign_in user }

      it "updates the account" do
        patch settings_account_path, params: valid_params
        account.reload
        expect(account.first_name).to eq("John")
        expect(account.last_name).to eq("Doe")
      end

      it "redirects to show after update" do
        patch settings_account_path, params: valid_params
        expect(response).to redirect_to(settings_account_path)
      end

      it "shows success notice" do
        patch settings_account_path, params: valid_params
        expect(flash[:notice]).to eq(I18n.t("settings.account.update.success"))
      end
    end

    context "when authenticated with invalid params" do
      before { sign_in user }

      it "does not update the account" do
        patch settings_account_path, params: { account: { first_name: "" } }
        account.reload
        expect(account.first_name).not_to eq("")
      end

      it "renders show with error" do
        patch settings_account_path, params: { account: { first_name: "" } }
        expect(response).to render_template(:show)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch settings_account_path, params: valid_params
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "DELETE #delete_profile_picture" do
    context "when authenticated" do
      before { sign_in user }

      it "deletes the profile picture" do
        account.image = Rack::Test::UploadedFile.new("spec/assets/photo1.jpg")
        account.save
        delete delete_profile_picture_settings_account_path
        account.reload
        expect(account.image_data).to be_nil
      end

      it "redirects to settings after deletion" do
        delete delete_profile_picture_settings_account_path
        expect(response).to redirect_to(settings_account_path)
      end

      it "shows success notice" do
        delete delete_profile_picture_settings_account_path
        expect(flash[:notice]).to eq(I18n.t("settings.account.delete_profile_picture.success"))
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete delete_profile_picture_settings_account_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end
end
