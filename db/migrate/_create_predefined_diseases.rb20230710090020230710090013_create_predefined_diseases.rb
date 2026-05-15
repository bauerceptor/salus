class CreatePredefinedDiseases < ActiveRecord::Migration[8.1]
  def change
    create_table :predefined_diseases, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false, default: ""
      t.string :related_names, array: true, default: []
      t.text :description, null: false, default: ""
      t.string :icd10_code, null: false, default: ""
      t.timestamps
    end

    add_index :predefined_diseases, :name, unique: true
  end
end
