require "rails_helper"

RSpec.describe FriendRequestsController, type: :request do
  let(:user) { create(:user) }
  let(:account) { user.account }
  let(:other_account) { create(:account) }

  describe "GET #index" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get friend_requests_path
        expect(response).to be_successful
      end

      it "assigns @received_requests" do
        request = create(:friend_request, account: other_account, friend: account)
        get friend_requests_path
        expect(assigns(:incoming)).to include(request)
      end

      it "assigns @sent_requests" do
        request = create(:friend_request, account: account, friend: other_account)
        get friend_requests_path
        expect(assigns(:outgoing)).to include(request)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get friend_requests_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        account_id: other_account.id
      }
    end

    context "when authenticated with valid params" do
      before { sign_in user }

      it "creates a new friend request" do
        expect {
          post friend_requests_path, params: valid_params
        }.to change(FriendRequest, :count).by(1)
      end

      it "redirects to accounts path" do
        post friend_requests_path, params: valid_params
        expect(response).to redirect_to(accounts_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post friend_requests_path, params: valid_params
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "POST #accept" do
    let!(:friend_request) { create(:friend_request, account: other_account, friend: account) }

    context "when authenticated" do
      before { sign_in user }

      it "accepts the friend request" do
        expect {
          patch friend_request_path(id: friend_request.id)
        }.to change(FriendRequest, :count).by(-1)
      end

      it "creates a friendship" do
        expect {
          patch friend_request_path(id: friend_request.id)
        }.to change(Friendship, :count).by(2)
      end

      it "redirects to friend requests path" do
        patch friend_request_path(id: friend_request.id)
        expect(response).to redirect_to(friend_requests_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch friend_request_path(id: friend_request.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:friend_request) { create(:friend_request, account: account, friend: other_account) }

    context "when authenticated" do
      before { sign_in user }

      it "destroys the friend request" do
        expect {
          delete friend_request_path(id: friend_request.id)
        }.to change(FriendRequest, :count).by(-1)
      end

      it "redirects to friend requests path" do
        delete friend_request_path(id: friend_request.id)
        expect(response).to redirect_to(friend_requests_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete friend_request_path(id: friend_request.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end
end