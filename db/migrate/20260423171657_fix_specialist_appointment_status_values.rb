class FixSpecialistAppointmentStatusValues < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE specialist_appointments SET status = 'scheduled' WHERE status = '0'"
    execute "UPDATE specialist_appointments SET status = 'confirmed' WHERE status = '1'"
    execute "UPDATE specialist_appointments SET status = 'completed' WHERE status = '2'"
    execute "UPDATE specialist_appointments SET status = 'cancelled' WHERE status = '3'"
  end

  def down
    execute "UPDATE specialist_appointments SET status = '0' WHERE status = 'scheduled'"
    execute "UPDATE specialist_appointments SET status = '1' WHERE status = 'confirmed'"
    execute "UPDATE specialist_appointments SET status = '2' WHERE status = 'completed'"
    execute "UPDATE specialist_appointments SET status = '3' WHERE status = 'cancelled'"
  end
end
