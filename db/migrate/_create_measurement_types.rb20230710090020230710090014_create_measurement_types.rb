class CreateMeasurementTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :measurement_types, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false, default: ""
      t.references :unit, null: false, type: :uuid
      t.string :lower_limit, default: "", null: false
      t.string :upper_limit, default: "", null: false
      t.string :critical_lower_limit, default: ""
      t.string :critical_upper_limit, default: ""
      t.boolean :is_active, default: true
      t.timestamps
    end

    add_index :measurement_types, :unit_id, if_not_exists: true
  end
end
