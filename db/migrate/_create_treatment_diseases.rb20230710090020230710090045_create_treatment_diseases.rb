class CreateTreatmentDiseases < ActiveRecord::Migration[8.1]
  def change
    create_table :treatment_diseases, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :treatment, null: false, type: :uuid
      t.references :disease, null: false, type: :uuid
      t.timestamps
    end
    add_index :treatment_diseases, %i[treatment_id disease_id], unique: true
  end
end
