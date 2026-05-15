class CreateGroupMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :group_members, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :group, null: false, type: :uuid
      t.references :account, null: false, type: :uuid
      t.string :role, limit: 50, default: "member"
      t.timestamps
    end
    add_index :group_members, %i[group_id account_id], unique: true
  end
end
