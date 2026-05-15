class AddCreatesGroupToPredefinedDiseases < ActiveRecord::Migration[8.1]
  def change
    add_column :predefined_diseases, :creates_group, :boolean, default: true, null: false
  end
end
