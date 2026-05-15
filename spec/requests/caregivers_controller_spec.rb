require "rails_helper"

RSpec.describe CaregiversController, type: :request do
  let(:user) { create(:user) }
  let(:account) { user.account }
  let(:caregiver_account) { create(:account) }

  describe "GET #index" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get caregivers_path
        expect(response).to be_successful
      end

      it "assigns @caregivers" do
        caregiver = create(:caregiver, account: account, caregiver_account: caregiver_account, is_accepted: true)
        get caregivers_path
        expect(assigns(:caregivers)).to include(caregiver)
      end

      it "only shows accepted caregivers" do
        accepted = create(:caregiver, account: account, caregiver_account: caregiver_account, is_accepted: true)
        pending = create(:caregiver, account: account, caregiver_account: create(:account), is_accepted: false)
        get caregivers_path
        expect(assigns(:caregivers)).to include(accepted)
        expect(assigns(:caregivers)).not_to include(pending)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get caregivers_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "GET #pending" do
    context "when authenticated" do
      before { sign_in user }

      it "assigns @pending_requests" do
        pending = create(:caregiver, account: account, caregiver_account: caregiver_account, is_accepted: false)
        get pending_caregivers_path, as: :turbo_stream
        expect(assigns(:pending_requests)).to include(pending)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get pending_caregivers_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "GET #new" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get new_caregiver_path
        expect(response).to be_successful
      end

      it "assigns @caregiver" do
        get new_caregiver_path
        expect(assigns(:caregiver)).to be_a_new(Caregiver)
      end

      it "assigns @potential_caregivers" do
        caregiver_account
        get new_caregiver_path
        expect(assigns(:potential_caregivers)).to be_present
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get new_caregiver_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        caregiver: {
          caregiver_account_id: caregiver_account.id,
          relationship: "family"
        }
      }
    end

    context "when authenticated with valid params" do
      before { sign_in user }

      it "creates a new caregiver relationship" do
        expect do
          post caregivers_path, params: valid_params
        end.to change(Caregiver, :count).by(1)
      end

      it "redirects to caregivers path" do
        post caregivers_path, params: valid_params
        expect(response).to redirect_to(caregivers_path)
      end
    end

    context "when authenticated with invalid params" do
      before { sign_in user }

      it "does not create a new caregiver" do
        expect do
          post caregivers_path, params: { caregiver: { relationship: "" } }
        end.not_to change(Caregiver, :count)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post caregivers_path, params: valid_params
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:caregiver) { create(:caregiver, account: account, caregiver_account: caregiver_account) }

    context "when authenticated" do
      before { sign_in user }

      it "destroys the caregiver relationship" do
        expect do
          delete caregiver_path(id: caregiver.id)
        end.to change(Caregiver, :count).by(-1)
      end

      it "redirects to caregivers path" do
        delete caregiver_path(id: caregiver.id)
        expect(response).to redirect_to(caregivers_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete caregiver_path(id: caregiver.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "POST #accept" do
    let!(:caregiver) { create(:caregiver, account: account, caregiver_account: caregiver_account, is_accepted: false) }

    context "when authenticated" do
      before { sign_in user }

      it "accepts the caregiver request" do
        patch accept_caregiver_path(id: caregiver.id)
        caregiver.reload
        expect(caregiver.is_accepted).to be true
      end

      it "redirects to pending caregivers path" do
        patch accept_caregiver_path(id: caregiver.id)
        expect(response).to redirect_to(pending_caregivers_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch accept_caregiver_path(id: caregiver.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "DELETE #reject" do
    let!(:caregiver) { create(:caregiver, account: account, caregiver_account: caregiver_account, is_accepted: false) }

    context "when authenticated" do
      before { sign_in user }

      it "rejects and destroys the caregiver request" do
        expect do
          delete reject_caregiver_path(id: caregiver.id)
        end.to change(Caregiver, :count).by(-1)
      end

      it "redirects to pending caregivers path" do
        delete reject_caregiver_path(id: caregiver.id)
        expect(response).to redirect_to(pending_caregivers_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete reject_caregiver_path(id: caregiver.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end
end
