class CreateDiseaseSymptomUpdates < ActiveRecord::Migration[8.1]
  def change
    create_table :disease_symptom_updates, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :disease_symptom, null: false, type: :uuid
      t.string :status, null: false, default: ""
      t.text :notes
      t.timestamps
    end
  end
end
