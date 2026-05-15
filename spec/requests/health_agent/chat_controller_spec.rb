require "rails_helper"

RSpec.describe HealthAgent::ChatController, type: :request do
  let(:user) { create(:user, :specialist) }
  let(:account) { user.account }

  before do
    sign_in user
  end

  describe "GET #index" do
    context "when authenticated" do
      let!(:conversation) { create(:health_agent_conversation, account: account) }

      before do
        create_list(:health_agent_message, 3, conversation: conversation, role: :user)
        create_list(:health_agent_message, 2, conversation: conversation, role: :assistant)
      end

      it "renders the chat index page" do
        get health_agent_chat_index_path
        expect(response).to have_http_status(:ok)
      end

      it "assigns messages ordered by created_at asc" do
        get health_agent_chat_index_path
        messages = assigns(:messages)
        expect(messages.count).to eq(5)
      end

      it "assigns the conversation" do
        get health_agent_chat_index_path
        expect(assigns(:conversation)).to eq(conversation)
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in" do
        get health_agent_chat_index_path
        expect(response).to redirect_to("/specialist/sign_in")
      end
    end
  end

  describe "POST #create" do
    let(:valid_params) { { content: "Hello, I have a question about my medication." } }

    it "creates messages and returns JSON" do
      mock_service = instance_double(HealthAgentService)
      allow(HealthAgentService).to receive(:new).with(account: account,
                                                      specialist: user.specialist)
                                                .and_return(mock_service)
      allow(mock_service).to receive(:ask).and_return("I'm here to help with your health questions.")

      post health_agent_chat_index_path, params: valid_params

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["user_message"]["role"]).to eq("user")
      expect(json["ai_response"]["role"]).to eq("assistant")
    end

    context "when persona is specialist" do
      let(:params) { { content: "Specialist question", persona: "specialist" } }

      it "creates conversation with specialist persona" do
        mock_service = instance_double(HealthAgentService)
        allow(HealthAgentService).to receive(:new).and_return(mock_service)
        allow(mock_service).to receive(:ask).and_return("Specialist response.")

        expect do
          post health_agent_chat_index_path, params: params
        end.to change(HealthAgentConversation.where(persona: :specialist), :count).by(1)
      end
    end

    context "when message content is empty" do
      let(:invalid_params) { { content: "" } }

      it "does not create a message" do
        expect do
          post health_agent_chat_index_path, params: invalid_params
        end.not_to change(HealthAgentMessage, :count)
      end

      it "returns unprocessable entity" do
        post health_agent_chat_index_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with file attachment" do
      let(:file) { fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "test_image.png"), "image/png") }

      it "creates message with attached file" do
        mock_service = instance_double(HealthAgentService)
        allow(HealthAgentService).to receive(:new).and_return(mock_service)
        allow(mock_service).to receive(:ask).and_return("Got your attachment.")

        expect do
          post health_agent_chat_index_path,
               params: { content: "Here is my reading.", attachment: file }
        end.to change(HealthAgentMessage, :count).by(2)

        message = HealthAgentMessage.role_user.last
        expect(message.attachment).to be_attached
      end

      it "returns JSON with attachment URL" do
        mock_service = instance_double(HealthAgentService)
        allow(HealthAgentService).to receive(:new).and_return(mock_service)
        allow(mock_service).to receive(:ask).and_return("Got your attachment.")

        post health_agent_chat_index_path,
             params: { content: "Here is my reading.", attachment: file }

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["user_message"]["attachment_url"]).to be_present
      end
    end

    context "with voice recording" do
      let(:audio_file) do
        fixture_file_upload(Rails.root.join("spec", "fixtures", "files", "test_audio.mp3"), "audio/mpeg")
      end

      it "creates message with audio attachment" do
        mock_service = instance_double(HealthAgentService)
        allow(HealthAgentService).to receive(:new).and_return(mock_service)
        allow(mock_service).to receive(:ask).and_return("Heard your voice message.")

        expect do
          post health_agent_chat_index_path,
               params: { content: "Voice message", attachment: audio_file }
        end.to change(HealthAgentMessage, :count).by(2)

        message = HealthAgentMessage.role_user.last
        expect(message.attachment).to be_attached
        expect(message.attachment.content_type).to include("audio")
      end
    end
  end
end
