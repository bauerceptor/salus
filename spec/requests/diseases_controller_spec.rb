require "rails_helper"

RSpec.describe DiseasesController, type: :request do
  let(:user) { create(:user) }
  let(:account) { user.account }

  describe "GET #index" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get diseases_path
        expect(response).to be_successful
      end

      it "assigns @diseases" do
        disease = create(:disease, account: account)
        get diseases_path
        expect(assigns(:diseases)).to include(disease)
      end

      it "paginates diseases" do
        create_list(:disease, 7, account: account)
        get diseases_path
        expect(assigns(:pagy)).to be_present
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get diseases_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "GET #new" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get new_disease_path
        expect(response).to be_successful
      end

      it "assigns a new disease" do
        get new_disease_path
        expect(assigns(:disease)).to be_a_new(Disease)
      end

      it "assigns @predefined_diseases" do
        create(:predefined_disease)
        get new_disease_path
        expect(assigns(:predefined_diseases)).to be_present
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get new_disease_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        disease: {
          name: "Test Disease",
          diagnosed_at: Time.zone.today,
          severity: 1,
          predefined_disease_id: create(:predefined_disease).id
        }
      }
    end

    context "when authenticated with valid params" do
      before { sign_in user }

      it "creates a new disease" do
        expect do
          post diseases_path, params: valid_params
        end.to change(Disease, :count).by(1)
      end

      it "redirects to index after creation" do
        post diseases_path, params: valid_params
        expect(response).to redirect_to(diseases_path)
      end
    end

    context "when authenticated with invalid params" do
      before { sign_in user }

      it "does not create a new disease" do
        expect do
          post diseases_path, params: { disease: { name: "" } }
        end.not_to change(Disease, :count)
      end

      it "renders new template with error" do
        post diseases_path, params: { disease: { name: "" } }
        expect(response).to render_template(:new)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post diseases_path, params: valid_params
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "GET #show" do
    let(:disease) { create(:disease, account: account) }

    context "when authenticated as owner" do
      before { sign_in user }

      it "returns a successful response" do
        get disease_path(id: disease.id)
        expect(response).to be_successful
      end

      it "assigns @disease" do
        get disease_path(id: disease.id)
        expect(assigns(:disease)).to eq(disease)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get disease_path(id: disease.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "GET #edit" do
    let(:disease) { create(:disease, account: account) }

    context "when authenticated as owner" do
      before { sign_in user }

      it "returns a successful response" do
        get edit_disease_path(id: disease.id)
        expect(response).to be_successful
      end

      it "assigns @disease" do
        get edit_disease_path(id: disease.id)
        expect(assigns(:disease)).to eq(disease)
      end

      it "assigns @selected_disease_id" do
        get edit_disease_path(id: disease.id)
        expect(assigns(:selected_disease_id)).to eq(disease.predefined_disease.id)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get edit_disease_path(id: disease.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "PATCH #update" do
    let(:disease) { create(:disease, account: account) }
    let(:valid_params) do
      {
        disease: {
          severity: 2
        }
      }
    end

    context "when authenticated as owner with valid params" do
      before { sign_in user }

      it "updates the disease" do
        patch disease_path(id: disease.id), params: valid_params
        disease.reload
        expect(disease.severity).to eq(2)
      end

      it "redirects to show after update" do
        patch disease_path(id: disease.id), params: valid_params
        expect(response).to redirect_to(disease_url(id: disease.id, locale: I18n.locale))
      end
    end

    context "when authenticated with invalid params" do
      before { sign_in user }

      it "renders edit template with error" do
        patch disease_path(id: disease.id), params: { disease: { name: "" } }
        expect(response).to render_template(:edit)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch disease_path(id: disease.id), params: valid_params
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "DELETE #destroy" do
    let(:disease) { create(:disease, account: account) }

    context "when authenticated as owner" do
      before { sign_in user }

      it "destroys the disease" do
        delete disease_path(id: disease.id)
        expect do
          disease.reload
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "redirects to index after destruction" do
        delete disease_path(id: disease.id)
        expect(response).to redirect_to(diseases_url)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete disease_path(id: disease.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end
end
