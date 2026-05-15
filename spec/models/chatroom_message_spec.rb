require "rails_helper"

RSpec.describe ChatroomMessage, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:chatroom) }
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:reply_to_message).class_name("ChatroomMessage").optional }
    it { is_expected.to have_one_attached(:attachment) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:body) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:message_type).with_values(text: 0, photo: 1, video: 2, audio: 3, document: 4, voice_note: 5) }
  end

  describe "#has_attachment?" do
    let(:message) { build(:chatroom_message) }

    it "returns false when no attachment" do
      expect(message.has_attachment?).to be false
    end
  end

  describe "#read_by?" do
    let(:account1) { create(:account) }
    let(:account2) { create(:account) }
    let(:chatroom) { create(:chatroom, account1: account1, account2: account2) }
    let(:message) { create(:chatroom_message, chatroom: chatroom, account: account1, read_at: Time.current) }

    it "returns true when read by other account" do
      expect(message.read_by?(account2)).to be true
    end

    it "returns false when not read" do
      message.update(read_at: nil)
      expect(message.read_by?(account2)).to be false
    end

    it "returns false when checking own message" do
      expect(message.read_by?(account1)).to be false
    end
  end
end