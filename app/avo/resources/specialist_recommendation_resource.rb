class SpecialistRecommendationResource < Avo::BaseResource
  self.title = :id
  self.includes = []

  field :id, as: :id
  field :specialist, as: :belongs_to
  field :account, as: :belongs_to
  field :medication, as: :belongs_to
  field :treatment, as: :belongs_to
  field :recommendation_type, as: :select, options: %w[medication treatment]
  field :status, as: :select, options: %w[pending accepted rejected dismissed]
  field :name, as: :text
  field :dosage, as: :text
  field :notes, as: :textarea
  field :created_at, as: :date_time
  field :updated_at, as: :date_time
end
