class FixTreatmentUpdatesTable < ActiveRecord::Migration[8.1]
  def change
    unless column_exists?(:treatment_updates, :name)
      add_column :treatment_updates, :name, :string, default: "", null: false
    end
    unless column_exists?(:treatment_updates, :description)
      add_column :treatment_updates, :description, :text, default: "", null: false
    end
    add_column :treatment_updates, :update_date, :datetime unless column_exists?(:treatment_updates, :update_date)
    begin
      change_column_null :treatment_updates, :status, true
    rescue StandardError
      nil
    end
  end
end
