class CreateDiseaseSymptoms < ActiveRecord::Migration[8.1]
  def change
    create_table :disease_symptoms, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :disease, null: false, type: :uuid
      t.string :name, null: false, default: ""
      t.text :description
      t.string :severity, limit: 50, default: "mild"
      t.timestamps
    end
  end
end
