require "rails_helper"

RSpec.describe AccountsController, type: :request do
  let(:user) { create(:user) }
  let(:account) { user.account }

  describe "GET #index" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get accounts_path
        expect(response).to be_successful
      end

      it "assigns @accounts" do
        other_account = create(:account)
        get accounts_path
        expect(assigns(:accounts)).to include(other_account)
      end

      it "paginates accounts" do
        create_list(:account, 30)
        get accounts_path
        expect(assigns(:pagy)).to be_present
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get accounts_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "GET #show" do
    let(:other_account) { create(:account) }

    context "when authenticated as friend" do
      before do
        sign_in user
        create(:friendship, account: account, friend: other_account)
      end

      it "returns a successful response" do
        get account_path(id: other_account.id)
        expect(response).to be_successful
      end

      it "assigns @posts" do
        post = create(:post, account: other_account, group: create(:group))
        get account_path(id: other_account.id)
        expect(assigns(:posts)).to include(post)
      end
    end

    context "when authenticated but not friend" do
      before { sign_in user }

      it "redirects to root path" do
        get account_path(id: other_account.id)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get account_path(id: other_account.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end
end
