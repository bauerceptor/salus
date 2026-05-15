class AddSpecialToPredefinedDiseases < ActiveRecord::Migration[8.1]
  def change
    add_column :predefined_diseases, :special, :boolean, default: false, null: false
    add_index :predefined_diseases, :special
  end
end
