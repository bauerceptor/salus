class AddNameAndDescriptionToGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :groups, :name, :string, default: "", null: false
    add_column :groups, :description, :string, default: "", null: false
  end
end
