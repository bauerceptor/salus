class AddMissingColumnsToTables < ActiveRecord::Migration[8.1]
  def change
    add_column :measurements, :measurement_date, :datetime, if_not_exists: true
    add_column :measurements, :is_within_limits, :boolean, default: true, if_not_exists: true

    add_column :notes, :is_pinned, :boolean, default: false, if_not_exists: true
    add_column :notes, :background_color, :string, default: "", if_not_exists: true

    add_column :measurement_types, :unit_id, :uuid, null: false, default: -> { "gen_random_uuid()" }, if_not_exists: true
    add_foreign_key :measurement_types, :units, column: :unit_id, if_not_exists: true

    add_column :specialists, :specialization, :string, if_not_exists: true
    add_column :specialists, :specialization_description, :string, if_not_exists: true
  end
end
