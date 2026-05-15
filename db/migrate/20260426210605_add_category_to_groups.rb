class AddCategoryToGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :groups, :category, :integer, default: 0, null: false
    add_index :groups, :category
  end
end
