class AddAcknowledgedAtToSpecialistNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :specialist_notifications, :acknowledged_at, :datetime
    add_column :specialist_notifications, :acknowledgment_note, :text
    add_column :specialist_notifications, :deferred_until, :datetime
  end
end
