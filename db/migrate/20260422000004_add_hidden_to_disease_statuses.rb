class AddHiddenToDiseaseStatuses < ActiveRecord::Migration[7.1]
  def change
    add_column :disease_statuses, :hidden, :boolean, default: false, null: false
    add_column :disease_statuses, :hidden_at, :datetime
    add_index :disease_statuses, :hidden
  end
end
