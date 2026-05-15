class AddRoleToGroupMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :group_members, :role, :integer, default: 0, null: false
    add_index :group_members, :role
  end
end
