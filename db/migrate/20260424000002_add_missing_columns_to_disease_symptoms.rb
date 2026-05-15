class AddMissingColumnsToDiseaseSymptoms < ActiveRecord::Migration[7.1]
  def change
    add_column :disease_symptoms, :first_noticed_at, :date
  end
end
