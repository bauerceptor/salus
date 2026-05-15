class SpecialistAppointmentResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :specialist, as: :belongs_to
  field :patient, as: :belongs_to
  field :schedule, as: :belongs_to
  field :appointment_date, as: :date
  field :start_time, as: :text
  field :end_time, as: :text
  field :status, as: :text
  field :notes, as: :textarea
  # add fields here
end
