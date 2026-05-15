class CreateSpecialistSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :specialist_schedules, id: :uuid do |t|
      t.references :specialist, null: false, foreign_key: true, type: :uuid
      t.integer :day_of_week
      t.string :start_time, limit: 5
      t.string :end_time, limit: 5
      t.string :appointment_type, limit: 50
      t.integer :duration_minutes
      t.boolean :is_active, default: true
      t.timestamps
    end
  end
end
