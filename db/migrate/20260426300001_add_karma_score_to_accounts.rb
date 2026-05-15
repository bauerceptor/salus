class AddKarmaScoreToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :karma_score, :integer, default: 0, null: false
    add_index :accounts, :karma_score
  end
end
