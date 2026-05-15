require "rails_helper"

RSpec.describe Specialist::MedicationRequestsController, type: :request do
  let(:specialist_user) { create(:user, :specialist) }
  let(:patient_user) { create(:user) }
  let(:patient_account) { patient_user.account }

  before do
    create(:specialist_patient, specialist: specialist_user, account: patient_account, status: "active")
  end

  describe "GET #index" do
    context "when authenticated as specialist" do
      before { sign_in specialist_user }

      it "returns a successful response" do
        get specialist_medication_requests_path
        expect(response).to be_successful
      end

      it "assigns pending medication requests for my patients" do
        request = create(:medication_request, account: patient_account, status: "pending")
        get specialist_medication_requests_path
        expect(assigns(:medication_requests)).to include(request)
      end

      it "does not include approved requests" do
        approved_request = create(:medication_request, account: patient_account, status: "approved")
        get specialist_medication_requests_path
        expect(assigns(:medication_requests)).not_to include(approved_request)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get specialist_medication_requests_path
        expect(response).to redirect_to(specialist_new_session_path)
      end
    end
  end

  describe "PATCH #update - approve" do
    let!(:pending_request) do
      create(:medication_request, account: patient_account, status: "pending", medication_name: "Metformin",
                                  dosage: "500mg", frequency: "twice daily")
    end

    context "when authenticated as specialist" do
      before { sign_in specialist_user }

      it "approves the medication request" do
        patch specialist_medication_request_path(id: pending_request.id, status: "approved")
        pending_request.reload
        expect(pending_request.status).to eq("approved")
      end

      it "creates a Medication from the request" do
        expect do
          patch specialist_medication_request_path(id: pending_request.id, status: "approved")
        end.to change(Medication, :count).by(1)

        medication = Medication.last
        expect(medication.source).to eq("patient_request")
        expect(medication.medication_request_id).to eq(pending_request.id)
      end

      it "redirects to index after approval" do
        patch specialist_medication_request_path(id: pending_request.id, status: "approved")
        expect(response).to redirect_to(specialist_medication_requests_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch specialist_medication_request_path(id: pending_request.id, status: "approved")
        expect(response).to redirect_to(specialist_new_session_path)
      end
    end
  end

  describe "PATCH #update - reject" do
    let!(:pending_request) { create(:medication_request, account: patient_account, status: "pending") }

    context "when authenticated as specialist" do
      before { sign_in specialist_user }

      it "rejects the medication request" do
        patch specialist_medication_request_path(id: pending_request.id, status: "rejected")
        pending_request.reload
        expect(pending_request.status).to eq("rejected")
      end

      it "redirects to index after rejection" do
        patch specialist_medication_request_path(id: pending_request.id, status: "rejected")
        expect(response).to redirect_to(specialist_medication_requests_path)
      end

      it "does not create a Medication" do
        expect do
          patch specialist_medication_request_path(id: pending_request.id, status: "rejected")
        end.not_to change(Medication, :count)
      end
    end
  end

  describe "PATCH #update - already resolved" do
    let!(:resolved_request) { create(:medication_request, account: patient_account, status: "approved") }

    before { sign_in specialist_user }

    it "does not change status" do
      patch specialist_medication_request_path(id: resolved_request.id, status: "rejected")
      resolved_request.reload
      expect(resolved_request.status).to eq("approved")
    end
  end
end
