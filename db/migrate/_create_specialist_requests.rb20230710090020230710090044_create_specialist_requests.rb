class CreateSpecialistRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :specialist_requests, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :specialist, null: false, type: :uuid
      t.references :account, null: false, type: :uuid
      t.string :status, limit: 50, default: "pending"
      t.text :message
      t.timestamps
    end
    add_index :specialist_requests, %i[specialist_id account_id], unique: true
  end
end
