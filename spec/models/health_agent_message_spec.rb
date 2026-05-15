require "rails_helper"

RSpec.describe HealthAgentMessage, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:conversation).class_name("HealthAgentConversation") }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:role).with_values(user: 0, assistant: 1, system: 2).with_prefix(:role) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:content) }
  end

  describe "#attachment_data" do
    it "returns nil when no attachment" do
      message = create(:health_agent_message)
      expect(message.attachment_data).to be_nil
    end
  end
end
