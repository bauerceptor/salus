require "rails_helper"

RSpec.describe SpecialistMessagesController, type: :request do
  let(:user) { create(:user) }
  let(:specialist_user) { create(:user, :specialist) }
  let(:account) { user.account }

  before do
    create(:specialist, user: specialist_user)
    create(:specialist_patient, specialist: specialist_user, account: account, status: "active")
  end

  describe "GET #index" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get patient_messages_path
        expect(response).to be_successful
      end

      it "assigns @assigned_doctor" do
        get patient_messages_path
        expect(assigns(:assigned_doctor)).to be_present
      end

      it "assigns @new_message" do
        get patient_messages_path
        expect(assigns(:new_message)).to be_a_new(SpecialistMessage)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get patient_messages_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "GET #show" do
    let!(:message) do
      create(:specialist_message, specialist: specialist_user, account: account, sender_type: "patient")
    end

    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get patient_message_path(id: message.id, locale: I18n.locale)
        expect(response).to be_successful
      end

      it "assigns @message" do
        get patient_message_path(id: message.id, locale: I18n.locale)
        expect(assigns(:message)).to eq(message)
      end

      it "marks specialist messages as read" do
        specialist_msg = create(:specialist_message, specialist: specialist_user, account: account,
                                                     sender_type: "specialist", is_read: false)
        get patient_message_path(id: specialist_msg.id, locale: I18n.locale)
        specialist_msg.reload
        expect(specialist_msg.is_read).to be true
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get patient_message_path(id: message.id, locale: I18n.locale)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        specialist_message: {
          specialist_id: specialist_user.id,
          subject: "Test Subject",
          body: "Test message body"
        }
      }
    end

    context "when authenticated with valid params" do
      before { sign_in user }

      it "creates a new message" do
        expect do
          post patient_messages_path, params: valid_params
        end.to change(SpecialistMessage, :count).by(1)
      end

      it "redirects to patient_messages_path" do
        post patient_messages_path, params: valid_params
        expect(response).to redirect_to(patient_messages_path)
      end
    end

    context "when authenticated with invalid params" do
      before { sign_in user }

      it "does not create a new message" do
        expect do
          post patient_messages_path, params: { specialist_message: { body: "" } }
        end.not_to change(SpecialistMessage, :count)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post patient_messages_path, params: valid_params
        expect(response).to redirect_to(auth_new_session_path)
      end
    end

    context "authorization — patient must have active specialist relationship" do
      before do
        sign_in user
        SpecialistPatient.where(account: account).destroy_all
      end

      context "when patient has NO specialist assigned" do
        it "does NOT create a message" do
          expect do
            post patient_messages_path, params: valid_params
          end.not_to change(SpecialistMessage, :count)
        end

        it "redirects back with alert" do
          post patient_messages_path, params: valid_params
          expect(response).to redirect_to(patient_messages_path)
          follow_redirect!
          expect(flash[:alert]).to match(/No active specialist|not sent/i)
        end
      end

      context "when patient has pending (not active) specialist relationship" do
        let(:pending_specialist) { create(:user, :specialist) }

        before do
          create(:specialist_patient, specialist: pending_specialist, account: account, status: "pending")
        end

        it "does NOT create a message" do
          expect do
            post patient_messages_path,
                 params: { specialist_message: { specialist_id: pending_specialist.id, body: "Test message" } }
          end.not_to change(SpecialistMessage, :count)
        end
      end

      context "when patient attempts to forge specialist_id" do
        let(:other_specialist) { create(:user, :specialist) }
        let(:other_specialist_account) { create(:account) }
        let!(:other_sp) do
          create(:specialist_patient, specialist: other_specialist, account: other_specialist_account, status: "active")
        end

        it "does not allow sending to unassigned specialist" do
          expect do
            post patient_messages_path,
                 params: { specialist_message: { specialist_id: other_specialist.id, body: "Forged message" } }
          end.not_to change(SpecialistMessage, :count)
        end

        it "does not create message even with valid specialist_id param but wrong account" do
          post patient_messages_path,
               params: { specialist_message: { specialist_id: other_specialist.id, body: "Attempted forgery" } }
          expect(SpecialistMessage.where(specialist_id: other_specialist.id, account_id: account.id)).not_to exist
        end
      end
    end
  end
end
