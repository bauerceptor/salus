class CreateDiseaseCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :disease_categories, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false, default: ""
      t.string :color, limit: 20, default: "#000000"
      t.text :description
      t.timestamps
    end
  end
end
