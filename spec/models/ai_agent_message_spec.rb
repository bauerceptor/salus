require "rails_helper"

RSpec.describe AiAgentMessage, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:conversation).class_name("AiAgentConversation") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_presence_of(:role) }
    it { is_expected.to validate_inclusion_of(:role).in_array(%w[user assistant system]) }
  end

  describe "#attachment_data" do
    let(:conversation) { create(:ai_agent_conversation) }
    let(:message) { create(:ai_agent_message, conversation: conversation, attachments: { "key" => "value" }) }

    it "returns attachments hash" do
      expect(message.attachment_data).to eq({ "key" => "value" })
    end

    it "returns empty hash when no attachments" do
      message = create(:ai_agent_message, conversation: conversation, attachments: nil)
      expect(message.attachment_data).to eq({})
    end
  end
end
