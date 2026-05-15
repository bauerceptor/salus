class AddPredefinedSymptomIdToDiseaseSymptoms < ActiveRecord::Migration[8.1]
  def change
    add_column :disease_symptoms, :predefined_symptom_id, :uuid
    add_foreign_key :disease_symptoms, :predefined_symptoms, column: :predefined_symptom_id
  end
end
