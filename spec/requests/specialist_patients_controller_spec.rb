require "rails_helper"

RSpec.describe SpecialistPatientsController, type: :request do
  let(:user) { create(:user) }
  let(:specialist_user) { create(:user, :specialist) }
  let(:account) { user.account }

  describe "POST #create" do
    context "when authenticated" do
      before { sign_in user }

      it "creates a new specialist patient relationship" do
        expect do
          post request_care_path(specialist_id: specialist_user.id, locale: I18n.locale)
        end.to change(SpecialistPatient, :count).by(1)
      end

      it "redirects to specialists path with notice" do
        post request_care_path(specialist_id: specialist_user.id, locale: I18n.locale)
        expect(response).to redirect_to(specialists_path(locale: I18n.locale))
        expect(flash[:notice]).to include("Request sent")
      end

      context "when relationship already exists" do
        before do
          create(:specialist_patient, specialist: specialist_user, account: account, status: "pending")
        end

        it "does not create a duplicate relationship" do
          expect do
            post request_care_path(specialist_id: specialist_user.id, locale: I18n.locale)
          end.not_to change(SpecialistPatient, :count)
        end

        it "redirects with alert" do
          post request_care_path(specialist_id: specialist_user.id, locale: I18n.locale)
          expect(response).to redirect_to(specialists_path(locale: I18n.locale))
          expect(flash[:alert]).to include("already have a request")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post request_care_path(specialist_id: specialist_user.id, locale: I18n.locale)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "POST #request_appointment" do
    let(:specialist) { create(:specialist, user: specialist_user) }
    let!(:specialist_patient) do
      create(:specialist_patient, specialist: specialist_user, account: account, status: "active")
    end
    let!(:schedule) { create(:specialist_schedule, specialist: specialist, is_active: true) }

    context "when authenticated" do
      before { sign_in user }

      it "creates an appointment request" do
        expect do
          post appointment_request_path(
            specialist_id: specialist_user.id,
            schedule_id: schedule.id,
            appointment_date: Date.tomorrow.to_s,
            start_time: "10:00",
            locale: I18n.locale
          )
        end.to change(SpecialistAppointment, :count).by(1)
      end

      it "redirects with notice on success" do
        post appointment_request_path(
          specialist_id: specialist_user.id,
          schedule_id: schedule.id,
          appointment_date: Date.tomorrow.to_s,
          start_time: "10:00",
          locale: I18n.locale
        )
        expect(response).to redirect_to(patient_messages_path(locale: I18n.locale))
        expect(flash[:notice]).to include("Appointment request sent")
      end

      context "when specialist not found" do
        it "redirects with alert" do
          post appointment_request_path(
            specialist_id: specialist_user.id,
            schedule_id: schedule.id,
            appointment_date: Date.tomorrow.to_s,
            start_time: "10:00",
            locale: I18n.locale
          )
          expect(response).to redirect_to(patient_messages_path(locale: I18n.locale))
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post appointment_request_path(
          specialist_id: specialist_user.id,
          schedule_id: schedule.id,
          appointment_date: Date.tomorrow.to_s,
          start_time: "10:00",
          locale: I18n.locale
        )
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end
end
