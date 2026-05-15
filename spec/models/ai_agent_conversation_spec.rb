require "rails_helper"

RSpec.describe AiAgentConversation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:messages).class_name("AiAgentMessage").dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:account_id) }
  end

  describe "#last_message_preview" do
    let(:conversation) { create(:ai_agent_conversation) }

    it "returns truncated content of last message" do
      msg = create(:ai_agent_message, conversation: conversation, content: "A" * 100)
      expect(conversation.last_message_preview).to eq(msg.content.truncate(50))
    end

    it "returns nil when no messages" do
      expect(conversation.last_message_preview).to be_nil
    end
  end
end
