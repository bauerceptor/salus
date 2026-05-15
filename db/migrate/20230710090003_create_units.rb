class CreateUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :units, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false, default: ""
      t.string :symbol, null: false, default: ""
      t.text :description
      t.timestamps
    end
  end
end
