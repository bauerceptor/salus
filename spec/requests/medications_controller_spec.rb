require "rails_helper"

RSpec.describe MedicationsController, type: :request do
  let(:user) { create(:user) }
  let(:account) { user.account }

  describe "GET #index" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get medications_path
        expect(response).to be_successful
      end

      it "assigns @medications" do
        medication = create(:medication, account: account)
        get medications_path
        expect(assigns(:medications)).to include(medication)
      end

      it "paginates medications" do
        create_list(:medication, 26, account: account)
        get medications_path
        expect(assigns(:pagy)).to be_present
      end

      it "only includes active medications" do
        active_med = create(:medication, account: account, is_active: true)
        inactive_med = create(:medication, account: account, is_active: false)
        get medications_path
        expect(assigns(:medications)).to include(active_med)
        expect(assigns(:medications)).not_to include(inactive_med)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get medications_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "GET #new" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get new_medication_path
        expect(response).to be_successful
      end

      it "assigns a new medication" do
        get new_medication_path
        expect(assigns(:medication)).to be_a_new(Medication)
      end

      it "assigns @diseases" do
        disease = create(:disease, account: account)
        get new_medication_path
        expect(assigns(:diseases)).to include(disease)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get new_medication_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        medication: {
          name: "Aspirin",
          dosage: "500mg",
          frequency: "daily",
          start_date: Time.zone.today
        }
      }
    end

    context "when authenticated with valid params" do
      before { sign_in user }

      it "creates a new medication" do
        expect do
          post medications_path, params: valid_params
        end.to change(Medication, :count).by(1)
      end

      it "redirects to index after creation" do
        post medications_path, params: valid_params
        expect(response).to redirect_to(medications_path)
      end
    end

    context "when authenticated with invalid params" do
      before { sign_in user }

      it "does not create a new medication" do
        expect do
          post medications_path, params: { medication: { name: "" } }
        end.not_to change(Medication, :count)
      end

      it "renders new template with error" do
        post medications_path, params: { medication: { name: "" } }
        expect(response).to render_template(:new)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post medications_path, params: valid_params
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "GET #show" do
    let(:medication) { create(:medication, account: account) }

    context "when authenticated as owner" do
      before { sign_in user }

      it "returns a successful response" do
        get medication_path(id: medication.id)
        expect(response).to be_successful
      end

      it "assigns @medication" do
        get medication_path(id: medication.id)
        expect(assigns(:medication)).to eq(medication)
      end

      it "assigns @medication_schedules" do
        schedule = create(:medication_schedule, medication: medication)
        get medication_path(id: medication.id)
        expect(assigns(:medication_schedules)).to include(schedule)
      end

      it "assigns @medication_logs" do
        log = create(:medication_log, medication: medication, account: account)
        get medication_path(id: medication.id)
        expect(assigns(:medication_logs)).to include(log)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get medication_path(id: medication.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "GET #edit" do
    let(:medication) { create(:medication, account: account) }

    context "when authenticated as owner" do
      before { sign_in user }

      it "returns a successful response" do
        get edit_medication_path(id: medication.id)
        expect(response).to be_successful
      end

      it "assigns @medication" do
        get edit_medication_path(id: medication.id)
        expect(assigns(:medication)).to eq(medication)
      end

      it "assigns @diseases" do
        disease = create(:disease, account: account)
        get edit_medication_path(id: medication.id)
        expect(assigns(:diseases)).to include(disease)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get edit_medication_path(id: medication.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "PATCH #update" do
    let(:medication) { create(:medication, account: account) }
    let(:valid_params) do
      {
        medication: {
          dosage: "1000mg"
        }
      }
    end

    context "when authenticated as owner with valid params" do
      before { sign_in user }

      it "updates the medication" do
        patch medication_path(id: medication.id), params: valid_params
        medication.reload
        expect(medication.dosage).to eq("1000mg")
      end

      it "redirects to show after update" do
        patch medication_path(id: medication.id), params: valid_params
        expect(response).to redirect_to(medication_url(id: medication.id, locale: I18n.locale))
      end
    end

    context "when authenticated with invalid params" do
      before { sign_in user }

      it "renders edit template with error" do
        patch medication_path(id: medication.id), params: { medication: { name: "" } }
        expect(response).to render_template(:edit)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch medication_path(id: medication.id), params: valid_params
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "DELETE #destroy" do
    let(:medication) { create(:medication, account: account) }

    context "when authenticated as owner" do
      before { sign_in user }

      it "destroys the medication" do
        delete medication_path(id: medication.id)
        expect do
          medication.reload
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "redirects to index after destruction" do
        delete medication_path(id: medication.id)
        expect(response).to redirect_to(medications_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete medication_path(id: medication.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end
end
