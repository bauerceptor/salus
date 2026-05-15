class SpecialistScheduleResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :specialist, as: :belongs_to
  field :day_of_week, as: :number
  field :start_time, as: :text
  field :end_time, as: :text
  field :appointment_type, as: :text
  field :duration_minutes, as: :number
  field :is_active, as: :boolean
  # add fields here
end
