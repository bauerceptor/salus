class SpecialistNoteAttachmentResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :specialist_note, as: :belongs_to
  field :file_type, as: :text
  field :file_url, as: :text
  field :filename, as: :text
  # add fields here
end
