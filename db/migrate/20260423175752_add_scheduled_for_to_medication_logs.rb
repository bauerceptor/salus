class AddScheduledForToMedicationLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :medication_logs, :scheduled_for, :datetime
    add_index :medication_logs, :scheduled_for
  end
end
