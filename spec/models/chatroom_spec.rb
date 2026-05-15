require "rails_helper"

RSpec.describe Chatroom, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account1).class_name("Account") }
    it { is_expected.to belong_to(:account2).class_name("Account") }
    it { is_expected.to have_many(:chatroom_messages).dependent(:destroy) }
    it { is_expected.to have_many(:chatroom_participants).dependent(:destroy) }
  end

  describe "validations" do
  end

  describe "#other_participant" do
    let(:account1) { create(:account) }
    let(:account2) { create(:account) }
    let(:chatroom) { create(:chatroom, account1: account1, account2: account2) }

    context "when current_account is account1" do
      it "returns account2" do
        expect(chatroom.other_participant(account1)).to eq(account2)
      end
    end

    context "when current_account is account2" do
      it "returns account1" do
        expect(chatroom.other_participant(account2)).to eq(account1)
      end
    end
  end

  describe "#participants" do
    let(:account1) { create(:account) }
    let(:account2) { create(:account) }
    let(:chatroom) { create(:chatroom, account1: account1, account2: account2) }

    it "returns both participants" do
      expect(chatroom.participants).to match_array([account1, account2])
    end
  end

  describe "#last_message" do
    let(:chatroom) { create(:chatroom) }
    let!(:older_message) { create(:chatroom_message, chatroom: chatroom, created_at: 1.day.ago) }
    let!(:newer_message) { create(:chatroom_message, chatroom: chatroom, created_at: Time.current) }

    it "returns the most recent message" do
      expect(chatroom.last_message).to eq(newer_message)
    end
  end

  describe "#unread_count" do
    let(:chatroom) { create(:chatroom) }
    let(:account) { chatroom.account1 }
    let!(:read_message) { create(:chatroom_message, chatroom: chatroom, account: chatroom.account2, read_at: Time.current) }
    let!(:unread_message) { create(:chatroom_message, chatroom: chatroom, account: chatroom.account2, read_at: nil) }

    it "returns count of unread messages for the account" do
      expect(chatroom.unread_count(account)).to eq(1)
    end
  end
end