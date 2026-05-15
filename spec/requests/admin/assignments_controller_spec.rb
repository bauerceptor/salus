require "rails_helper"

RSpec.describe Admin::AssignmentsController, type: :request do
  describe "GET /admin/assignments" do
    let(:admin) { create(:admin) }

    before do
      allow_any_instance_of(Admin::BaseController).to receive(:authenticate_admin!).and_return(true)
      allow_any_instance_of(Admin::BaseController).to receive(:admin_signed_in?).and_return(true)
      allow_any_instance_of(Admin::BaseController).to receive(:current_admin).and_return(admin)
    end

    it "returns a successful response" do
      get admin_assignments_path
      expect(response).to have_http_status(:success)
    end

    it "renders the admin dashboard layout" do
      get admin_assignments_path
      expect(response).to render_template layout: "admin_dashboard"
    end

    it "shows the Assignments page title" do
      get admin_assignments_path
      expect(response.body).to include("Patient-Specialist Assignments")
    end

    context "with active assignments" do
      let(:specialist) { create(:user, :specialist) }
      let(:account) { create(:account) }

      before do
        create(:specialist_patient, specialist: specialist, account: account, status: "active")
      end

      it "shows the patient name in the assignment table" do
        get admin_assignments_path
        expect(response.body).to include(account.full_name)
      end

      it "shows the specialist email in the assignment table" do
        get admin_assignments_path
        expect(response.body).to include(specialist.email)
      end

      it "shows active status badge" do
        get admin_assignments_path
        expect(response.body).to include("Active")
      end
    end

    context "filtering" do
      let(:specialist) { create(:user, :specialist) }
      let(:patient) { create(:account) }

      it "defaults to showing all assignments" do
        create(:specialist_patient, specialist: specialist, account: patient, status: "active")
        get admin_assignments_path
        expect(response.body).to include(patient.full_name)
      end

      it "filters by active status" do
        create(:specialist_patient, specialist: specialist, account: patient, status: "active")
        get admin_assignments_path(filter: "active")
        expect(response.body).to include(patient.full_name)
      end

      it "filters by pending status" do
        create(:specialist_patient, specialist: specialist, account: patient, status: "pending")
        get admin_assignments_path(filter: "pending")
        expect(response.body).to include(patient.full_name)
      end

      it "filters by unassigned — patients with no specialist" do
        unassigned_patient = create(:account)
        get admin_assignments_path(filter: "unassigned")
        expect(response.body).to include(unassigned_patient.full_name)
      end

      it "unassigned filter does not show patients with a specialist" do
        create(:specialist_patient, specialist: specialist, account: patient, status: "active")
        get admin_assignments_path(filter: "unassigned")
        expect(response.body).not_to include(patient.full_name)
      end

      it "filters by specialist" do
        create(:specialist_patient, specialist: specialist, account: patient, status: "active")
        get admin_assignments_path(specialist_id: specialist.id)
        expect(response.body).to include(patient.full_name)
      end

      it "does not show patients of a different specialist when filtering" do
        other_specialist = create(:user, :specialist)
        create(:specialist_patient, specialist: other_specialist, account: patient, status: "active")
        get admin_assignments_path(specialist_id: specialist.id)
        expect(response.body).not_to include(patient.full_name)
      end
    end

    context "unassigned patients (orphaned)" do
      it "shows patients with no SpecialistPatient record" do
        orphan = create(:account)
        get admin_assignments_path(filter: "unassigned")
        expect(response.body).to include(orphan.full_name)
      end

      it "unassigned count matches patients with no specialist relationship" do
        create_list(:account, 3)
        get admin_assignments_path(filter: "unassigned")
        expect(response.body).to include("3")
      end
    end

    context "reassign actions" do
      let(:specialist) { create(:user, :specialist) }
      let(:account) { create(:account) }
      let!(:assignment) { create(:specialist_patient, specialist: specialist, account: account, status: "active") }

      it "shows reassign button on each row" do
        get admin_assignments_path
        expect(response.body).to include("Reassign")
      end

      it "shows bulk reassign button when assignments exist" do
        get admin_assignments_path
        expect(response.body).to include("Reassign Selected")
      end
    end

    context "empty states" do
      it "shows empty state when no assignments exist" do
        get admin_assignments_path
        expect(response.body).to include("No assignments found")
      end

      it "shows empty state for unassigned filter when all patients have specialists" do
        specialist = create(:user, :specialist)
        account = create(:account)
        create(:specialist_patient, specialist: specialist, account: account, status: "active")
        # Remove ALL other accounts from the database to ensure only our account exists
        Account.where.not(id: account.id).destroy_all
        get admin_assignments_path(filter: "unassigned")
        expect(response.body).to include("No unassigned patients")
      end
    end

    context "pagination" do
      it "paginates assignments beyond 20 records" do
        specialist = create(:user, :specialist)
        create_list(:specialist_patient, 25, specialist: specialist, status: "active")
        get admin_assignments_path
        expect(response.body).to include("Next")
      end
    end
  end

  describe "PATCH /admin/assignments" do
    let(:admin) { create(:admin) }

    before do
      allow_any_instance_of(Admin::BaseController).to receive(:authenticate_admin!).and_return(true)
      allow_any_instance_of(Admin::BaseController).to receive(:admin_signed_in?).and_return(true)
      allow_any_instance_of(Admin::BaseController).to receive(:current_admin).and_return(admin)
    end

    context "single reassign" do
      let(:specialist) { create(:user, :specialist) }
      let(:new_specialist) { create(:user, :specialist) }
      let(:account) { create(:account) }
      let!(:assignment) { create(:specialist_patient, specialist: specialist, account: account, status: "active") }

      it "updates the specialist_id on the assignment" do
        patch admin_assignment_path(id: assignment.id, specialist_id: new_specialist.id)
        assignment.reload
        expect(assignment.specialist_id).to eq(new_specialist.id)
      end

      it "redirects back to assignments index" do
        patch admin_assignment_path(id: assignment.id, specialist_id: new_specialist.id)
        expect(response).to redirect_to(admin_assignments_path)
      end

      it "shows success notice after reassign" do
        patch admin_assignment_path(id: assignment.id, specialist_id: new_specialist.id)
        follow_redirect!
        expect(flash[:notice]).to match(/reassigned/i)
      end
    end

    context "bulk reassign" do
      let(:specialist) { create(:user, :specialist) }
      let(:new_specialist) { create(:user, :specialist) }
      let!(:assignment_1) { create(:specialist_patient, specialist: specialist, status: "active") }
      let!(:assignment_2) { create(:specialist_patient, specialist: specialist, status: "active") }

      it "updates multiple assignments to new specialist" do
        patch bulk_reassign_admin_assignments_path(assignment_ids: [assignment_1.id, assignment_2.id],
                                                   specialist_id: new_specialist.id)
        assignment_1.reload
        assignment_2.reload
        expect(assignment_1.specialist_id).to eq(new_specialist.id)
        expect(assignment_2.specialist_id).to eq(new_specialist.id)
      end

      it "redirects back with success notice" do
        patch bulk_reassign_admin_assignments_path(assignment_ids: [assignment_1.id], specialist_id: new_specialist.id)
        expect(response).to redirect_to(admin_assignments_path)
      end
    end

    context "validation errors" do
      it "redirects with alert when reassigning to the same specialist" do
        specialist = create(:user, :specialist)
        account = create(:account)
        assignment = create(:specialist_patient, specialist: specialist, account: account, status: "active")

        patch admin_assignment_path(id: assignment.id, specialist_id: specialist.id)
        expect(response).to redirect_to(admin_assignments_path)
        follow_redirect!
        expect(flash[:alert]).to match(/already assigned/i)
      end

      it "redirects with alert when specialist_id is missing" do
        assignment = create(:specialist_patient, status: "active")
        patch admin_assignment_path(id: assignment.id, specialist_id: "")
        expect(response).to redirect_to(admin_assignments_path)
        follow_redirect!
        expect(flash[:alert]).to match(/select a specialist/i)
      end
    end
  end
end
