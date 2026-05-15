class MessageAttachmentResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :message, as: :belongs_to
  field :file_type, as: :text
  field :file_data, as: :text
  field :filename, as: :text
  field :content_type, as: :text
  # add fields here
end
