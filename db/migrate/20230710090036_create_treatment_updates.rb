class CreateTreatmentUpdates < ActiveRecord::Migration[8.1]
  def change
    create_table :treatment_updates, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :treatment, null: false, type: :uuid
      t.text :notes
      t.string :status, limit: 50
      t.timestamps
    end
  end
end
