class CreateEmergencyAlerts < ActiveRecord::Migration[8.1]
  def change
    create_table :emergency_alerts, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :emergency_contact, foreign_key: true, type: :uuid
      t.references :triggered_by, polymorphic: true, type: :uuid
      t.string :alert_type, null: false
      t.integer :status, default: 0, null: false
      t.text :message
      t.json :metadata, default: {}
      t.datetime :acknowledged_at
      t.timestamps
    end

    add_index :emergency_alerts, %i[account_id status]
    add_index :emergency_alerts, [:alert_type]
  end
end
