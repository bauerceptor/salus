# == Schema Information
#
# Table name: predefined_diseases
#
#  id            :uuid             not null, primary key
#  description   :text             default(""), not null
#  icd10_code    :string           default(""), not null
#  name          :string           default(""), not null
#  related_names :string           default([]), is an Array
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_predefined_diseases_on_name  (name) UNIQUE
#
require "rails_helper"

RSpec.describe PredefinedDisease, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:disease).dependent(:destroy) }
    it { is_expected.to have_many(:predefined_symptoms).dependent(:destroy) }
    it { is_expected.to have_one(:group).dependent(:destroy) }
  end

  describe "validations" do
    describe "name" do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_length_of(:name).is_at_most(100) }
    end

    describe "description" do
      it { is_expected.to validate_presence_of(:description) }
      it { is_expected.to validate_length_of(:description).is_at_most(500) }
    end

    describe "icd10_code" do
      it { is_expected.to validate_length_of(:icd10_code).is_at_most(10) }
      it { is_expected.to allow_value("").for(:icd10_code) }
    end
  end

  describe "callbacks" do
    describe "after_create :create_group" do
      let(:predefined_disease) { create(:predefined_disease) }

      it "creates a group" do
        expect(predefined_disease.group).to be_present
      end

      it "creates group with disease name" do
        expect(predefined_disease.group.name).to eq(predefined_disease.name)
      end

      it "creates group with community description" do
        expect(predefined_disease.group.description).to include(predefined_disease.name.titleize)
      end

      it "creates group with support category for liver diseases" do
        liver_disease = create(:predefined_disease, name: "hepatitis_b")
        expect(liver_disease.group.category).to eq("support")
      end

      it "creates group with general category for non-liver diseases" do
        non_liver_disease = create(:predefined_disease, name: "diabetes_type_1")
        expect(non_liver_disease.group.category).to eq("general")
      end

      context "when creates_group is false" do
        let(:predefined_disease) { create(:predefined_disease, :no_group) }

        it "does not create a group" do
          expect(predefined_disease.group).not_to be_present
        end
      end

      context "when special is true" do
        let(:special_disease) { create(:predefined_disease, special: true) }

        it "creates a group with general category" do
          expect(special_disease.group.category).to eq("general")
        end
      end
    end
  end

  describe "scopes" do
    describe ".special_groups" do
      it "returns only special diseases" do
        create(:predefined_disease, special: true)
        create(:predefined_disease, special: false)
        expect(described_class.special_groups.count).to eq(1)
        expect(described_class.special_groups.first.special).to be true
      end
    end

    describe ".disease_groups" do
      it "returns only non-special diseases" do
        create(:predefined_disease, special: true)
        create(:predefined_disease, special: false)
        expect(described_class.disease_groups.count).to eq(1)
        expect(described_class.disease_groups.first.special).to be false
      end
    end
  end
end
