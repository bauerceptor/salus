class CreateMedicationSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :medication_schedules, id: :uuid do |t|
      t.references :medication, null: false, foreign_key: true, type: :uuid
      t.string :day_of_week
      t.time :scheduled_time, null: false
      t.string :time_of_day
      t.boolean :is_active, default: true, null: false
      t.timestamps
    end

    add_index :medication_schedules, %i[medication_id is_active scheduled_time]
  end
end
