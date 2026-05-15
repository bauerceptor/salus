class CreateGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :groups, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :predefined_disease, type: :uuid, foreign_key: true
      t.string :name, default: "", null: false
      t.string :description, default: "", null: false
      t.timestamps
    end
  end
end
