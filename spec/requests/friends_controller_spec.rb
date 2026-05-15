require "rails_helper"

RSpec.describe FriendsController, type: :request do
  let(:user) { create(:user) }
  let(:account) { user.account }
  let(:friend_account) { create(:account) }

  before do
    create(:friendship, account: account, friend: friend_account)
  end

  describe "GET #index" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get account_friends_path(account_id: account.id)
        expect(response).to be_successful
      end

      it "assigns @friends" do
        get account_friends_path(account_id: account.id)
        expect(assigns(:friends)).to include(friend_account)
      end

      it "paginates friends" do
        Array.new(10) { create(:friendship, account: account, friend: create(:account)) }
        get account_friends_path(account_id: account.id)
        expect(assigns(:pagy)).to be_present
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get account_friends_path(account_id: account.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "DELETE #destroy" do
    context "when authenticated" do
      before { sign_in user }

      it "removes the friend" do
        expect {
          delete account_friend_path(account_id: account.id, id: friend_account.id)
        }.to change(Friendship.where(account: account), :count).by(-1)
      end

      it "redirects to friends index" do
        delete account_friend_path(account_id: account.id, id: friend_account.id)
        expect(response).to redirect_to(account_friends_path(account_id: account.id))
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete account_friend_path(account_id: account.id, id: friend_account.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end
end