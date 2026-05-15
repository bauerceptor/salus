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
#  creates_group :boolean          default: true, not null
#
# Indexes
#
#  index_predefined_diseases_on_name  (name) UNIQUE
#
class PredefinedDisease < ApplicationRecord
  after_create :create_group, if: :creates_group?

  has_many :disease, dependent: :destroy
  has_many :predefined_symptoms, dependent: :destroy
  has_one :group, dependent: :destroy

  validates :name, length: { maximum: 100 }, presence: true, uniqueness: true
  validates :description, length: { maximum: 500 }, presence: true
  validates :icd10_code, length: { maximum: 10 }, allow_blank: true

  LIVER_DISEASES = %w[hepatitis_b hepatitis_c cirrhosis nafld nash liver_cancer].freeze

  scope :liver_related, -> { where(name: LIVER_DISEASES) }
  scope :special_groups, -> { where(special: true) }
  scope :disease_groups, -> { where(special: false) }

  private

  def create_group
    category = if special
                 :general
               elsif LIVER_DISEASES.include?(name)
                 :support
               else
                 :general
               end
    Group.create!(
      predefined_disease_id: id,
      name: name,
      description: "Community for people with #{name.titleize}",
      category: category
    )
  end
end
