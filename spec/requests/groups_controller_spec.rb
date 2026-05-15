require "rails_helper"

RSpec.describe GroupsController, type: :request do
  let(:user) { create(:user) }
  let(:account) { user.account }
  let(:predefined_disease) { create(:predefined_disease, :liver_related) }
  let(:group) { create(:group, predefined_disease: predefined_disease) }

  describe "GET #index" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get groups_path
        expect(response).to be_successful
      end

      it "assigns @account_groups" do
        group.accounts << account
        get groups_path
        expect(assigns(:account_groups)).to include(group)
      end

      it "assigns @available_groups" do
        create(:disease, account: account, predefined_disease: predefined_disease)
        get groups_path
        expect(assigns(:available_groups).map(&:predefined_disease_id)).to include(predefined_disease.id)
      end

      it "paginates groups" do
        create_list(:group, 15, predefined_disease: predefined_disease)
        get groups_path
        expect(assigns(:pagy_account)).to be_present
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get groups_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "POST #join_group" do
    context "when authenticated" do
      before { sign_in user }

      it "adds current account to group" do
        expect do
          post join_group_path(id: group.id)
        end.to change { group.accounts.count }.by(1)
      end

      it "redirects to groups path with notice" do
        post join_group_path(id: group.id)
        expect(response).to redirect_to(groups_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post join_group_path(id: group.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "DELETE #leave_group" do
    context "when authenticated and member of group" do
      before do
        sign_in user
        group.accounts << account
      end

      it "removes current account from group" do
        expect do
          delete leave_group_path(id: group.id)
        end.to change { group.accounts.count }.by(-1)
      end

      it "redirects to groups path with notice" do
        delete leave_group_path(id: group.id)
        expect(response).to redirect_to(groups_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete leave_group_path(id: group.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end
end
