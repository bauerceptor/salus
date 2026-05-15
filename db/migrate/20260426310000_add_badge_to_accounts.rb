class AddBadgeToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :badge, :integer, default: 0, null: false
    add_index :accounts, :badge
  end
end
