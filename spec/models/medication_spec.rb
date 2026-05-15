# == Schema Information
#
# Table name: medications
#
#  id                             :uuid             not null, primary key
#  account_id                     :uuid             not null
#  disease_id                     :uuid
#  name                           :string           not null
#  dosage                         :string           not null
#  frequency                      :string           not null
#  instructions                   :text
#  start_date                     :date
#  end_date                       :date
#  is_active                      :boolean          default: true, not null
#  notes                          :text
#  reminder_enabled               :boolean          default: true, not null
#  reminder_minutes_before        :integer          default: 15
#  email_reminder_enabled         :boolean          default: false, not null
#  source                         :string
#  specialist_recommendation_id   :uuid
#  medication_request_id          :uuid
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#
# Indexes
#
#  index_medications_on_account_id                    (account_id)
#  index_medications_on_account_id_and_is_active        (account_id, is_active)
#  index_medications_on_source                          (source)
#  index_medications_on_specialist_recommendation_id   (specialist_recommendation_id)
#  index_medications_on_medication_request_id          (medication_request_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (disease_id => diseases.id)
#  fk_rails_...  (specialist_recommendation_id => specialist_recommendations.id)
#  fk_rails_...  (medication_request_id => medication_requests.id)
#
require "rails_helper"

RSpec.describe Medication, type: :model do
  describe "factory" do
    it { expect(build(:medication)).to be_valid }
  end

  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:disease).optional }
    it { is_expected.to belong_to(:specialist_recommendation).class_name("SpecialistRecommendation").optional }
    it { is_expected.to belong_to(:medication_request).optional }

    it { is_expected.to have_many(:medication_schedules).dependent(:destroy) }
    it { is_expected.to have_many(:medication_logs).dependent(:destroy) }
  end

  describe "validations" do
    describe "name" do
      it { is_expected.to validate_presence_of(:name) }
    end

    describe "dosage" do
      it { is_expected.to validate_presence_of(:dosage) }
    end

    describe "frequency" do
      it { is_expected.to validate_presence_of(:frequency) }
    end

    describe "source" do
      it { is_expected.to allow_value("patient_request").for(:source) }
      it { is_expected.to allow_value("doctor_prescription").for(:source) }
      it { is_expected.to allow_value(nil).for(:source) }
      it { is_expected.not_to allow_value("invalid").for(:source) }
    end

    describe "start_date" do
      it { is_expected.to allow_value(Time.zone.today).for(:start_date) }
      it { is_expected.to allow_value(1.day.from_now).for(:start_date) }
      it { is_expected.to allow_value(3.days.from_now).for(:start_date) }
      it { is_expected.not_to allow_value(7.days.ago).for(:start_date) }
      it { is_expected.not_to allow_value(4.days.from_now).for(:start_date) }
    end

    describe "end_date" do
      context "when start_date is today" do
        subject { build(:medication, start_date: Time.zone.today) }

        it { is_expected.to allow_value(Time.zone.today).for(:end_date) }
        it { is_expected.to allow_value(1.day.from_now).for(:end_date) }
        it { is_expected.to allow_value(3.days.from_now).for(:end_date) }
        it { is_expected.not_to allow_value(1.day.ago).for(:end_date) }
        it { is_expected.not_to allow_value(4.days.from_now).for(:end_date) }
      end

      context "when end_date is before start_date" do
        subject { build(:medication, start_date: Time.zone.today, end_date: 1.day.ago) }

        it { is_expected.not_to allow_value(1.day.ago).for(:end_date) }
      end
    end
  end

  describe "scopes" do
    describe ".active" do
      let_it_be(:active_med) { create(:medication, is_active: true) }
      let_it_be(:inactive_med) { create(:medication, is_active: false) }

      it "returns only active medications" do
        expect(described_class.active).to include(active_med)
        expect(described_class.active).not_to include(inactive_med)
      end
    end

    describe ".patient_request" do
      let_it_be(:patient_req_med) { create(:medication, :patient_request) }
      let_it_be(:doctor_rx_med) { create(:medication, :doctor_prescription) }

      it "returns only patient-requested medications" do
        expect(described_class.patient_request).to include(patient_req_med)
        expect(described_class.patient_request).not_to include(doctor_rx_med)
      end
    end

    describe ".doctor_prescribed" do
      let_it_be(:doctor_rx_med) { create(:medication, :doctor_prescription) }
      let_it_be(:patient_req_med) { create(:medication, :patient_request) }

      it "returns only doctor-prescribed medications" do
        expect(described_class.doctor_prescribed).to include(doctor_rx_med)
        expect(described_class.doctor_prescribed).not_to include(patient_req_med)
      end
    end
  end

  describe "FREQUENCIES constant" do
    it "includes expected frequency types" do
      expect(described_class::FREQUENCIES.keys).to include(:once_daily, :twice_daily, :as_needed)
    end
  end
end
