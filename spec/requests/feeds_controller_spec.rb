require "rails_helper"

RSpec.describe FeedsController, type: :request do
  let(:user) { create(:user) }
  let(:account) { user.account }

  describe "GET #show" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get feed_path
        expect(response).to be_successful
      end

      it "assigns @pagy" do
        get feed_path
        expect(assigns(:pagy)).to be_present
      end

      it "assigns @feed_items" do
        get feed_path
        expect(assigns(:feed_items)).to be_an(Array)
      end

      context "with posts in user's groups" do
        let(:group) { create(:group) }

        before do
          create(:group_member, group: group, account: account)
          create(:post, account: account, group: group)
        end

        it "includes posts from user's groups" do
          get feed_path
          expect(assigns(:feed_items).map(&:item)).to include(kind_of(Post))
        end
      end

      context "with disease statuses from friends" do
        let(:friend_account) { create(:account) }
        let(:disease) { create(:disease, account: friend_account) }

        before do
          create(:friendship, account: account, friend: friend_account)
          create(:disease_status, disease: disease)
        end

        it "includes disease statuses from friends" do
          get feed_path
          feed_items = assigns(:feed_items)
          expect(feed_items.map(&:item)).to include(kind_of(DiseaseStatus))
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get feed_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end
end
