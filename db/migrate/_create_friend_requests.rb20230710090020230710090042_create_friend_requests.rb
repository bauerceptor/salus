class CreateFriendRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :friend_requests, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :account, null: false, type: :uuid
      t.references :friend, null: false, type: :uuid
      t.string :status, limit: 50, default: "pending"
      t.timestamps
    end
    add_index :friend_requests, %i[account_id friend_id], unique: true
  end
end
