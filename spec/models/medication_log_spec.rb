require "rails_helper"

RSpec.describe MedicationLog, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:medication) }
    it { is_expected.to belong_to(:medication_schedule).optional }
  end

  describe "status enum" do
    it "defines the expected statuses" do
      expect(described_class.statuses).to eq(
        "pending" => "pending",
        "taken" => "taken",
        "skipped" => "skipped",
        "missed" => "missed",
        "delayed" => "delayed"
      )
    end

    it "stores status as string values" do
      log = create(:medication_log, status: :taken)
      expect(log.reload.status).to eq("taken")
    end
  end

  describe "enum predicate methods" do
    it "responds to status predicate methods" do
      log = build(:medication_log, status: :pending)
      expect(log).to be_pending
      expect(log).not_to be_taken
      expect(log).not_to be_skipped
      expect(log).not_to be_missed
    end

    it "reflects taken status" do
      log = create(:medication_log, status: :taken)
      expect(log).to be_taken
      expect(log).not_to be_pending
    end
  end

  describe "enum scopes" do
    it "filters logs by status" do
      pending_log = create(:medication_log, status: :pending)
      taken_log = create(:medication_log, status: :taken)

      expect(described_class.pending).to include(pending_log)
      expect(described_class.pending).not_to include(taken_log)
      expect(described_class.taken).to include(taken_log)
    end
  end

  describe ".for_account" do
    it "returns logs for the specified account" do
      account = create(:account)
      other_account = create(:account)
      their_log = create(:medication_log, account: account)
      other_log = create(:medication_log, account: other_account)

      expect(described_class.for_account(account)).to include(their_log)
      expect(described_class.for_account(account)).not_to include(other_log)
    end
  end

  describe ".recent" do
    it "returns logs from the last 30 days" do
      account = create(:account)
      recent = create(:medication_log, account: account, scheduled_for: 5.days.ago)
      old = create(:medication_log, account: account, scheduled_for: 60.days.ago)

      expect(described_class.recent).to include(recent)
      expect(described_class.recent).not_to include(old)
    end
  end

  describe ".for_date" do
    it "returns logs for the specified date" do
      account = create(:account)
      target_date = Time.zone.today
      matching = create(:medication_log, account: account, scheduled_for: target_date.to_time + 10.hours)
      other_day = create(:medication_log, account: account, scheduled_for: target_date.yesterday)

      expect(described_class.for_date(target_date)).to include(matching)
      expect(described_class.for_date(target_date)).not_to include(other_day)
    end
  end

  describe "#mark_as_taken" do
    it "updates status to taken and sets taken_at" do
      log = create(:medication_log, status: :pending)

      log.mark_as_taken(notes: "Took with food")

      expect(log).to be_taken
      expect(log.taken_at).to be_present
      expect(log.notes).to eq("Took with food")
    end
  end

  describe "#mark_as_skipped" do
    it "updates status to skipped" do
      log = create(:medication_log, status: :pending)

      log.mark_as_skipped(notes: "Skipped dose")

      expect(log).to be_skipped
      expect(log.notes).to eq("Skipped dose")
    end
  end

  describe "#mark_as_missed" do
    it "updates status to missed when pending and past scheduled time" do
      log = create(:medication_log, status: :pending, scheduled_for: 1.hour.ago)

      log.mark_as_missed

      expect(log).to be_missed
    end

    it "does not update when not pending" do
      log = create(:medication_log, status: :taken, scheduled_for: 1.hour.ago)

      log.mark_as_missed

      expect(log).not_to be_missed
      expect(log).to be_taken
    end

    it "does not update when scheduled time is in the future" do
      log = create(:medication_log, status: :pending, scheduled_for: 1.hour.from_now)

      log.mark_as_missed

      expect(log).not_to be_missed
      expect(log).to be_pending
    end
  end
end
