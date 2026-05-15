class AddNotificationPreferencesToMedications < ActiveRecord::Migration[8.1]
  def change
    add_column :medications, :reminder_enabled, :boolean, default: true, null: false
    add_column :medications, :reminder_minutes_before, :integer, default: 15
    add_column :medications, :email_reminder_enabled, :boolean, default: false, null: false
  end
end
