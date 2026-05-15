class AddIntensityToDiseaseSymptomUpdates < ActiveRecord::Migration[8.1]
  def change
    add_column :disease_symptom_updates, :intensity, :integer, default: 1
    add_column :disease_symptom_updates, :update_date, :datetime
    change_column_null :disease_symptom_updates, :status, true
  end
end
