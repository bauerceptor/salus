require "rails_helper"

RSpec.describe Specialist::SchedulesController, type: :request do
  let(:specialist_user) { create(:user, :specialist) }

  before do
    create(:specialist, user: specialist_user)
    sign_in specialist_user
  end

  describe "GET #index" do
    it "returns http success" do
      get specialist_schedules_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #new" do
    it "returns http success" do
      get new_specialist_schedule_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      let(:valid_params) do
        { specialist_schedule: { day_of_week: 1, start_time: "09:00", end_time: "17:00", duration_minutes: 60 } }
      end

      it "creates a new schedule" do
        expect do
          post specialist_schedules_path, params: valid_params
        end.to change(SpecialistSchedule, :count).by(1)
      end

      it "redirects after creation" do
        post specialist_schedules_path, params: valid_params
        expect(response).to redirect_to(specialist_schedules_path)
      end
    end
  end

  describe "GET #edit" do
    let!(:schedule) { create(:specialist_schedule, specialist: specialist_user.specialist) }

    it "returns http success" do
      get edit_specialist_schedule_path(id: schedule.id)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH #update" do
    let!(:schedule) { create(:specialist_schedule, specialist: specialist_user.specialist) }
    let(:update_params) do
      { specialist_schedule: { day_of_week: 2 } }
    end

    it "updates the schedule" do
      patch specialist_schedule_path(id: schedule.id), params: update_params
      schedule.reload
      expect(schedule.day_of_week).to eq(2)
    end

    it "redirects after update" do
      patch specialist_schedule_path(id: schedule.id), params: update_params
      expect(response).to redirect_to(specialist_schedules_path)
    end
  end

  describe "DELETE #destroy" do
    let!(:schedule) { create(:specialist_schedule, specialist: specialist_user.specialist) }

    it "destroys the schedule" do
      expect do
        delete specialist_schedule_path(id: schedule.id)
      end.to change(SpecialistSchedule, :count).by(-1)
    end

    it "redirects after destroy" do
      delete specialist_schedule_path(id: schedule.id)
      expect(response).to redirect_to(specialist_schedules_path)
    end
  end
end

RSpec.describe Specialist::SchedulesController, type: :request do
  describe "authentication" do
    it "redirects to login when not authenticated" do
      get specialist_schedules_path
      expect(response).to redirect_to(specialist_new_session_path)
    end
  end
end
