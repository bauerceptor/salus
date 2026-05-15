class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :notifiable, polymorphic: true, type: :uuid
      t.string :title, null: false
      t.text :body
      t.string :notification_type, null: false
      t.datetime :read_at
      t.json :data, default: {}
      t.timestamps
    end

    add_index :notifications, %i[account_id read_at]
    add_index :notifications, %i[account_id notification_type]
  end
end
