class ChangeMeasurementValueToString < ActiveRecord::Migration[8.1]
  def change
    change_column :measurements, :value, :string, using: "value::text"
  end
end