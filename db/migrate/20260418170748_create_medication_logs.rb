class CreateMedicationLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :medication_logs, id: :uuid do |t|
      t.references :medication, null: false, foreign_key: true, type: :uuid
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :medication_schedule, foreign_key: true, type: :uuid
      t.integer :status, default: 0, null: false
      t.text :notes
      t.datetime :taken_at
      t.datetime :scheduled_for
      t.timestamps
    end

    add_index :medication_logs, %i[medication_id scheduled_for]
    add_index :medication_logs, %i[account_id status scheduled_for]
  end
end
