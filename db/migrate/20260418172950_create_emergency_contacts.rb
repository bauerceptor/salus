class CreateEmergencyContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :emergency_contacts, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :phone_number, null: false
      t.string :relationship, null: false
      t.boolean :is_primary, default: false, null: false
      t.boolean :notify_on_emergency, default: true, null: false
      t.timestamps
    end

    add_index :emergency_contacts, %i[account_id is_primary]
  end
end
