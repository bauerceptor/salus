class CreateTreatmentRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :treatment_requests, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :account_id, null: false
      t.uuid :specialist_id
      t.string :title, null: false
      t.text :description
      t.date :start_date
      t.string :status, default: "pending", null: false
      t.text :rejection_reason
      t.datetime :requested_at, null: false
      t.datetime :reviewed_at
      t.timestamps
    end

    add_index :treatment_requests, :account_id
    add_index :treatment_requests, :status
    add_index :treatment_requests, %i[account_id status]
  end
end
