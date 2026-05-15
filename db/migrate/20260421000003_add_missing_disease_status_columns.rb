class AddMissingDiseaseStatusColumns < ActiveRecord::Migration[8.1]
  def change
    add_column :disease_statuses, :content, :text, default: "", null: false
    add_column :disease_statuses, :mood, :integer, default: 3, null: false
  end
end
