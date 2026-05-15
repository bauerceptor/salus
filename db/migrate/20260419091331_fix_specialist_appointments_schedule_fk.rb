class FixSpecialistAppointmentsScheduleFk < ActiveRecord::Migration[8.1]
  def change
    drop_table :specialist_appointments, if_exists: true

    create_table :specialist_appointments, id: :uuid do |t|
      t.references :specialist, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :patient, null: false, foreign_key: { to_table: :accounts }, type: :uuid
      t.references :schedule, null: false, foreign_key: { to_table: :specialist_schedules }, type: :uuid
      t.date :appointment_date
      t.string :start_time, limit: 5
      t.string :end_time, limit: 5
      t.string :status, limit: 50, default: "scheduled"
      t.text :notes
      t.timestamps
    end
  end
end
