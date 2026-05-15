# == Schema Information
#
# Table name: treatments
#
#  id                             :uuid             not null, primary key
#  account_id                     :uuid             not null
#  approval_status                :string           default: "pending", not null
#  approved_at                    :datetime
#  approved_by_id                 :uuid
#  description                    :text             default: "", not null
#  effectiveness                  :integer          default: 0, not null
#  end_date                       :date
#  hidden_at                      :datetime
#  is_finished                    :boolean          default: FALSE, not null
#  is_hidden                      :boolean          default: FALSE, not null
#  name                           :string           default: "", not null
#  requested_at                   :datetime
#  source                         :string
#  specialist_recommendation_id   :uuid
#  start_date                     :date
#  status                         :string           default: "active"
#  title                          :string           default: "", not null
#  updated_at                     :datetime         not null
#  created_at                     :datetime         not null
#
# Indexes
#
#  index_treatments_on_account_id                    (account_id)
#  index_treatments_on_source                        (source)
#  index_treatments_on_specialist_recommendation_id  (specialist_recommendation_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (specialist_recommendation_id => specialist_recommendations.id)
#
require "rails_helper"

RSpec.describe Treatment, type: :model do
  describe "factory" do
    it { expect(build(:treatment)).to be_valid }
  end

  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:specialist_recommendation).class_name("SpecialistRecommendation").optional }

    it do
      is_expected.to(
        have_many(:updates).dependent(:destroy)
        .class_name("TreatmentUpdate").inverse_of(:treatment)
      )
    end

    it { is_expected.to have_many(:treatment_diseases).dependent(:destroy) }
    it { is_expected.to have_many(:diseases).through(:treatment_diseases) }
  end

  describe "validations" do
    describe "title" do
      it { is_expected.to validate_presence_of(:title) }
      it { is_expected.to validate_length_of(:title).is_at_most(100) }
    end

    describe "description" do
      it { is_expected.to validate_presence_of(:description) }
      it { is_expected.to validate_length_of(:description).is_at_most(500) }
    end

    describe "effectiveness" do
      it { is_expected.to validate_presence_of(:effectiveness) }

      it do
        is_expected.to validate_numericality_of(:effectiveness)
          .only_integer
          .is_greater_than_or_equal_to(1)
          .is_less_than_or_equal_to(5)
      end
    end

    describe "start_date" do
      it { is_expected.to validate_presence_of(:start_date) }
      it { is_expected.to allow_value(Time.zone.today).for(:start_date) }
      it { is_expected.to allow_value(1.day.from_now).for(:start_date) }
      it { is_expected.to allow_value(3.days.from_now).for(:start_date) }
      it { is_expected.not_to allow_value(7.days.ago).for(:start_date) }
      it { is_expected.not_to allow_value(4.days.from_now).for(:start_date) }
    end

    describe "end_date" do
      context "when start_date is present and in valid range" do
        subject { build(:treatment, start_date: Time.zone.today) }

        it { is_expected.to allow_value(Time.zone.today).for(:end_date) }
        it { is_expected.to allow_value(1.day.from_now).for(:end_date) }
        it { is_expected.to allow_value(3.days.from_now).for(:end_date) }
        it { is_expected.not_to allow_value(1.day.ago).for(:end_date) }
        it { is_expected.not_to allow_value(4.days.from_now).for(:end_date) }
      end

      context "when start_date is older than 3 days" do
        subject { build(:treatment, start_date: 7.days.ago) }

        it { is_expected.not_to allow_value(7.days.ago).for(:start_date) }
      end

      context "when end_date is before start_date" do
        subject { build(:treatment, start_date: Time.zone.today, end_date: 1.day.ago) }

        it { is_expected.not_to allow_value(1.day.ago).for(:end_date) }
      end
    end

    describe "source" do
      it { is_expected.to allow_value("patient_request").for(:source) }
      it { is_expected.to allow_value("doctor_prescription").for(:source) }
      it { is_expected.to allow_value(nil).for(:source) }
      it { is_expected.not_to allow_value("invalid").for(:source) }
    end

    describe "approval_status" do
      it { is_expected.to validate_inclusion_of(:approval_status).in_array(%w[pending approved rejected]) }
    end
  end

  describe "scopes" do
    describe ".doctor_prescribed" do
      let_it_be(:doctor_rx) { create(:treatment, :doctor_prescription) }
      let_it_be(:patient_req) { create(:treatment, :patient_request) }

      it "returns only doctor prescribed treatments" do
        expect(described_class.doctor_prescribed).to include(doctor_rx)
        expect(described_class.doctor_prescribed).not_to include(patient_req)
      end
    end
  end

  describe "#days_difference" do
    context "when the date is valid" do
      let_it_be(:treatment) { build(:treatment, start_date: 7.days.ago) }

      it "returns the difference in days between today and start_date" do
        expect(treatment.days_difference).to eq(7)
      end
    end

    context "when the date is invalid" do
      let_it_be(:treatment) { build(:treatment, start_date: "2023-23-343 432:324") }

      it "raises an error" do
        expect { treatment.days_difference }.to raise_error(TypeError)
      end
    end
  end
end
