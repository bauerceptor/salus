class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false, default: ""
      t.timestamps
    end

    add_index :roles, :name, unique: true
  end
end
