class CreateMedicationRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :medication_requests, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.uuid :specialist_id, null: false
      t.string :medication_name, null: false
      t.string :dosage
      t.string :frequency
      t.text :reason
      t.string :status, default: "pending", null: false
      t.text :rejection_reason
      t.datetime :requested_at, null: false
      t.datetime :reviewed_at
      t.timestamps
    end

    add_index :medication_requests, %i[specialist_id status]
    add_index :medication_requests, :account_id
  end
end
