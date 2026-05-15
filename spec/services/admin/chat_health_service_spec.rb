require "rails_helper"

RSpec.describe Admin::ChatHealthService do
  describe "#health_stats" do
    let(:service) { described_class.new }
    let(:specialist_user) { create(:user, :specialist) }

    before do
      specialist_user.reload
    end

    it "returns an array of specialist health stats" do
      stats = service.health_stats
      expect(stats).to be_an(Array)
    end

    it "includes specialist info for each stat" do
      stats = service.health_stats
      specialist_stat = stats.find { |s| s[:specialist_id] == specialist_user.id }
      expect(specialist_stat).to include(:specialist_id, :specialist_name, :specialization)
      expect(specialist_stat[:specialist_name]).to eq(specialist_user.account.full_name)
      expect(specialist_stat[:specialization]).to eq(specialist_user.specialist.specialization)
    end

    it "tracks messages sent in last 30 days" do
      create(:specialist_message, specialist: specialist_user, sender_type: "specialist", created_at: 1.day.ago)
      create(:specialist_message, specialist: specialist_user, sender_type: "patient", created_at: 2.days.ago)

      stats = service.health_stats
      specialist_stat = stats.find { |s| s[:specialist_id] == specialist_user.id }
      expect(specialist_stat[:messages_sent_last_30d]).to eq(2)
    end

    it "tracks zero history patients" do
      patient_with_history = create(:account)
      create(:specialist_message, specialist: specialist_user, account: patient_with_history,
                                  sender_type: "patient")

      patient_without_history = create(:account)
      create(:specialist_patient, specialist: specialist_user, account: patient_without_history, status: "active")
    end

    it "shows last message timestamp" do
      create(:specialist_message, specialist: specialist_user, sender_type: "specialist", created_at: 5.days.ago)
      most_recent = create(:specialist_message, specialist: specialist_user, sender_type: "patient",
                                                created_at: 1.day.ago)

      stats = service.health_stats
      specialist_stat = stats.find { |s| s[:specialist_id] == specialist_user.id }
      expect(specialist_stat[:last_message_at]).to be_within(1.minute).of(most_recent.created_at)
    end

    it "indicates when no messages exist" do
      stats = service.health_stats
      specialist_stat = stats.find { |s| s[:specialist_id] == specialist_user.id }
      expect(specialist_stat[:messages_sent_last_30d]).to eq(0)
      expect(specialist_stat[:last_message_at]).to be_nil
    end

    it "aggregates across multiple specialists" do
      specialist2 = create(:user, :specialist)
      specialist2.reload

      create(:specialist_message, specialist: specialist_user, sender_type: "specialist")
      create(:specialist_message, specialist: specialist2, sender_type: "specialist")

      stats = service.health_stats
      expect(stats.size).to eq(2)
    end

    it "gracefully handles specialists with no patients" do
      stats = service.health_stats
      specialist_stat = stats.find { |s| s[:specialist_id] == specialist_user.id }
      expect(specialist_stat[:zero_history_patients]).to eq(0)
      expect(specialist_stat[:messages_sent_last_30d]).to eq(0)
    end
  end
end
