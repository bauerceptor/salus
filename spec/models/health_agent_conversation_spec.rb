require "rails_helper"

RSpec.describe HealthAgentConversation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account) }

    it {
      is_expected.to have_many(:messages).class_name("HealthAgentMessage").dependent(:destroy).with_foreign_key("conversation_id")
    }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:persona).with_values(patient: 0, specialist: 1).with_prefix(:persona) }
    it { is_expected.to define_enum_for(:status).with_values(active: 0, archived: 1).with_prefix(:status) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:account_id) }
  end

  describe "#last_message_preview" do
    let(:conversation) { create(:health_agent_conversation) }

    it "returns truncated content of last message" do
      msg = create(:health_agent_message, conversation: conversation, content: "A" * 100)
      expect(conversation.last_message_preview).to eq(msg.content.truncate(50))
    end

    it "returns nil when no messages" do
      expect(conversation.last_message_preview).to be_nil
    end
  end
end
