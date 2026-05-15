class SpecialistNoteResource < Avo::BaseResource
  self.title = :id
  self.includes = []

  field :id, as: :id
  field :specialist, as: :belongs_to
  field :account, as: :belongs_to
  field :content, as: :textarea
  field :note_type, as: :select, options: %w[observation recommendation warning]
  field :created_at, as: :date_time
  field :updated_at, as: :date_time
end
