class SpecialistMessageResource < Avo::BaseResource
  self.title = :id
  self.includes = []

  field :id, as: :id
  field :specialist, as: :belongs_to
  field :account, as: :belongs_to
  field :specialist_recommendation, as: :belongs_to
  field :sender_type, as: :select, options: %w[specialist patient]
  field :subject, as: :text
  field :body, as: :textarea
  field :parent, as: :belongs_to
  field :is_read, as: :boolean
  field :created_at, as: :date_time
  field :updated_at, as: :date_time
end
