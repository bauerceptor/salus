class CreateSpecialistNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :specialist_notifications, id: :uuid do |t|
      t.references :specialist, foreign_key: { to_table: :users }, type: :uuid, null: false
      t.references :patient, foreign_key: { to_table: :accounts }, type: :uuid, null: false
      t.string :notification_type, null: false
      t.string :title, null: false
      t.text :message
      t.references :notifiable, polymorphic: true, type: :uuid
      t.boolean :is_read, default: false, null: false
      t.timestamps
    end

    add_index :specialist_notifications, %i[specialist_id is_read]
    add_index :specialist_notifications, :notification_type
  end
end
