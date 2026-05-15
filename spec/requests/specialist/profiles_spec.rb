require "rails_helper"

RSpec.describe Specialist::ProfilesController, type: :request do
  let(:specialist_user) { create(:user, :specialist) }

  before do
    create(:specialist, user: specialist_user)
    sign_in specialist_user
  end

  describe "GET /profile" do
    it "returns http success" do
      get specialist_profile_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /profile/edit" do
    it "returns http success" do
      get specialist_edit_profile_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /profile" do
    it "redirects after successful update" do
      patch specialist_profile_path, params: { specialist: { specialization: "Cardiology" } }
      expect(response).to redirect_to(specialist_profile_path)
    end
  end
end
