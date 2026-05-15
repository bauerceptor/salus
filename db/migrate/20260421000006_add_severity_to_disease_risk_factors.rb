class AddSeverityToDiseaseRiskFactors < ActiveRecord::Migration[8.1]
  def change
    add_column :disease_risk_factors, :severity, :integer, default: 1, null: false
  end
end
