class AddApplicationFieldsToSpecialistRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :specialist_requests, :field_of_expertise, :string
    add_column :specialist_requests, :specialization, :string
    add_column :specialist_requests, :specialization_description, :string
  end
end
