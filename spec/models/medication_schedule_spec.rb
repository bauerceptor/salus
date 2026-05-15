require "rails_helper"

RSpec.describe MedicationSchedule, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:medication) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:scheduled_time) }
  end

  describe "scopes" do
    let(:medication) { create(:medication) }

    describe ".active" do
      it "returns only active schedules" do
        active = create(:medication_schedule, medication: medication, is_active: true)
        inactive = create(:medication_schedule, medication: medication, is_active: false)
        expect(described_class.active).to include(active)
        expect(described_class.active).not_to include(inactive)
      end
    end

    describe ".upcoming" do
      it "returns only upcoming schedules" do
        upcoming = create(:medication_schedule, medication: medication, is_active: true,
                                                scheduled_time: 1.hour.from_now)
        past = create(:medication_schedule, medication: medication, is_active: true, scheduled_time: 1.hour.ago)
        expect(described_class.upcoming).to include(upcoming)
        expect(described_class.upcoming).not_to include(past)
      end
    end
  end
end
