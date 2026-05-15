require "rails_helper"

RSpec.describe PostsController, type: :request do
  let(:user) { create(:user) }
  let(:account) { user.account }
  let(:disease) { create(:disease, account: account) }

  describe "GET #index" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get account_posts_path(account_id: account.id, locale: I18n.locale)
        expect(response).to be_successful
      end

      it "assigns @posts" do
        status = create(:disease_status, disease: disease)
        get account_posts_path(account_id: account.id, locale: I18n.locale)
        expect(assigns(:posts)).to include(status)
      end

      it "paginates posts" do
        create_list(:disease_status, 15, disease: disease)
        get account_posts_path(account_id: account.id, locale: I18n.locale)
        expect(assigns(:pagy)).to be_present
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get account_posts_path(account_id: account.id, locale: I18n.locale)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "GET #new" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get new_account_post_path(account_id: account.id, locale: I18n.locale)
        expect(response).to be_successful
      end

      it "assigns @post" do
        get new_account_post_path(account_id: account.id, locale: I18n.locale)
        expect(assigns(:post)).to be_a_new(DiseaseStatus)
      end

      it "assigns @diseases" do
        disease
        get new_account_post_path(account_id: account.id, locale: I18n.locale)
        expect(assigns(:diseases)).to include(disease)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get new_account_post_path(account_id: account.id, locale: I18n.locale)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        disease_status: {
          disease_id: disease.id,
          content: "Test post content",
          status: "diagnosed",
          mood: 3
        }
      }
    end

    context "when authenticated with valid params" do
      before { sign_in user }

      it "creates a new post" do
        expect do
          post account_posts_path(account_id: account.id, locale: I18n.locale), params: valid_params
        end.to change(DiseaseStatus, :count).by(1)
      end

      it "redirects after creation" do
        post account_posts_path(account_id: account.id, locale: I18n.locale), params: valid_params
        expect(response).to have_http_status(:redirect)
      end
    end

    context "when authenticated with invalid params (no disease)" do
      before { sign_in user }

      it "does not create a new post" do
        expect do
          post account_posts_path(account_id: account.id, locale: I18n.locale),
               params: { disease_status: { content: "Test" } }
        end.not_to change(DiseaseStatus, :count)
      end

      it "renders new with error" do
        post account_posts_path(account_id: account.id, locale: I18n.locale),
             params: { disease_status: { content: "Test" } }
        expect(response).to render_template(:new)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post account_posts_path(account_id: account.id, locale: I18n.locale), params: valid_params
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end
end
