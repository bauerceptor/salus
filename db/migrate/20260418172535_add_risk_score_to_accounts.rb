class AddRiskScoreToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :risk_score, :integer, default: 0
    add_column :accounts, :last_risk_assessment, :datetime
  end
end
