require "rails_helper"

RSpec.describe MeasurementsController, type: :request do
  let(:user) { create(:user) }
  let(:account) { user.account }
  let(:measurement_type) { create(:measurement_type, name: "weight") }

  describe "GET #index" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get measurements_path
        expect(response).to be_successful
      end

      it "assigns @latest hash" do
        get measurements_path
        expect(assigns(:latest)).to be_a(Hash)
      end

      it "assigns @measurements grouped by date" do
        create(:measurement, account: account, measurement_type: measurement_type)
        get measurements_path
        expect(assigns(:measurements)).to be_a(Hash)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get measurements_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "GET #new" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response for weight" do
        get new_measurements_path(measurement_type: "weight")
        expect(response).to be_successful
      end

      it "assigns a new measurement" do
        get new_measurements_path(measurement_type: "weight")
        expect(assigns(:measurement)).to be_a_new(Measurement)
      end

      it "raises error for invalid measurement type" do
        expect do
          get new_measurements_path(measurement_type: "invalid")
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get new_measurements_path(measurement_type: "weight")
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        measurement: {
          value: "75.5",
          measurement_date: Time.zone.now
        }
      }
    end

    context "when authenticated with valid params" do
      before { sign_in user }

      it "creates a new measurement" do
        expect do
          post create_measurements_path(measurement_type: "weight"), params: valid_params
        end.to change(Measurement, :count).by(1)
      end

      it "redirects to index after creation" do
        post create_measurements_path(measurement_type: "weight"), params: valid_params
        expect(response).to redirect_to(measurements_path)
      end

      it "shows success notice" do
        post create_measurements_path(measurement_type: "weight"), params: valid_params
        expect(flash[:success]).to be_present
      end
    end

    context "when authenticated with invalid params" do
      before { sign_in user }

      it "does not create a new measurement" do
        expect do
          post create_measurements_path(measurement_type: "weight"), params: { measurement: { value: "" } }
        end.not_to change(Measurement, :count)
      end

      it "renders new template with error" do
        post create_measurements_path(measurement_type: "weight"), params: { measurement: { value: "" } }
        expect(response).to render_template(:new)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post create_measurements_path(measurement_type: "weight"), params: valid_params
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "GET #show" do
    let(:measurement) { create(:measurement, account: account, measurement_type: measurement_type) }

    context "when authenticated as owner" do
      before { sign_in user }

      it "returns a successful response" do
        get measurement_path(id: measurement.id)
        expect(response).to be_successful
      end

      it "assigns @measurement" do
        get measurement_path(id: measurement.id)
        expect(assigns(:measurement)).to eq(measurement)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get measurement_path(id: measurement.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "GET #show_by_day" do
    let(:date) { Time.zone.today }

    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get show_by_day_measurements_path(day: date)
        expect(response).to be_successful
      end

      it "assigns @measurements for the day" do
        create(:measurement, account: account, measurement_type: measurement_type, measurement_date: date)
        get show_by_day_measurements_path(day: date)
        expect(assigns(:measurements)).not_to be_empty
      end

      it "paginates measurements" do
        get show_by_day_measurements_path(day: date)
        expect(assigns(:pagy)).to be_present
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get show_by_day_measurements_path(day: date)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "PATCH #update" do
    let(:measurement) { create(:measurement, account: account, measurement_type: measurement_type) }
    let(:valid_params) do
      {
        measurement: {
          value: "80.0"
        }
      }
    end

    context "when authenticated as owner with valid params" do
      before { sign_in user }

      it "updates the measurement" do
        patch measurement_path(id: measurement.id), params: valid_params
        measurement.reload
        expect(measurement.value).to eq(80.0)
      end

      it "redirects to show after update" do
        patch measurement_path(id: measurement.id), params: valid_params
        expect(response).to redirect_to(measurement_path(measurement))
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch measurement_path(id: measurement.id), params: valid_params
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "DELETE #destroy" do
    let(:measurement) { create(:measurement, account: account, measurement_type: measurement_type) }

    context "when authenticated as owner" do
      before { sign_in user }

      it "destroys the measurement" do
        delete measurement_path(id: measurement.id)
        expect do
          measurement.reload
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "redirects to index after destruction" do
        delete measurement_path(id: measurement.id)
        expect(response).to redirect_to(measurements_url)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete measurement_path(id: measurement.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end
end
