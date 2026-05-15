class SpecialistNotificationResource < Avo::BaseResource
  self.title = :id
  self.includes = []

  field :id, as: :id
  field :specialist, as: :belongs_to
  field :patient, as: :belongs_to
  field :notification_type, as: :select,
                            options: %w[sos_alert missed_medication low_adherence abnormal_measurement new_message recommendation_response]
  field :title, as: :text
  field :message, as: :textarea
  field :notifiable, as: :belongs_to
  field :is_read, as: :boolean
  field :created_at, as: :date_time
  field :updated_at, as: :date_time
end
