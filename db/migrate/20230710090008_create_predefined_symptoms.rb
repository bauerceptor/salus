class CreatePredefinedSymptoms < ActiveRecord::Migration[8.1]
  def change
    create_table :predefined_symptoms, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :predefined_disease, type: :uuid, foreign_key: true
      t.string :name, null: false, default: ""
      t.string :related_names, array: true, default: []
      t.text :description, null: false, default: ""
      t.timestamps
    end

    add_index :predefined_symptoms, :name, unique: true
  end
end
