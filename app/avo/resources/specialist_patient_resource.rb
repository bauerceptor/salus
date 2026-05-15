class SpecialistPatientResource < Avo::BaseResource
  self.title = :id
  self.includes = []

  field :id, as: :id
  field :specialist, as: :belongs_to
  field :account, as: :belongs_to
  field :status, as: :select, options: %w[pending active inactive]
  field :relationship_type, as: :select, options: %w[primary_care consulting specialist]
  field :notes, as: :textarea
  field :created_at, as: :date_time
  field :updated_at, as: :date_time
end
