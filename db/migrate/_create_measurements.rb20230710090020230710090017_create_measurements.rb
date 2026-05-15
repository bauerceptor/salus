class CreateMeasurements < ActiveRecord::Migration[8.1]
  def change
    create_table :measurements, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :account, null: false, type: :uuid
      t.references :measurement_type, null: false, type: :uuid
      t.decimal :value, precision: 10, scale: 2
      t.text :notes
      t.timestamps
    end
  end
end
