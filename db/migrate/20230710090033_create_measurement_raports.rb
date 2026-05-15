class CreateMeasurementRaports < ActiveRecord::Migration[8.1]
  def change
    create_table :measurement_raports, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :account, null: false, type: :uuid
      t.string :title, limit: 255
      t.text :content
      t.string :raport_type, limit: 50, default: "weekly"
      t.timestamps
    end
  end
end
