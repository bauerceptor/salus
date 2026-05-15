class AddMissingColumnsToMeasurementRaports < ActiveRecord::Migration[8.1]
  def change
    unless column_exists?(:measurement_raports, :name)
      add_column :measurement_raports, :name, :string, default: "", null: false
    end
    return if column_exists?(:measurement_raports, :attachment_data)

    add_column :measurement_raports, :attachment_data, :jsonb
  end
end
