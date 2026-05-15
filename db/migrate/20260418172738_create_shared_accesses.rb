class CreateSharedAccesses < ActiveRecord::Migration[8.1]
  def change
    create_table :shared_accesses, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :shared_with_account, foreign_key: { to_table: :accounts }, type: :uuid
      t.references :shareable, polymorphic: true, type: :uuid
      t.integer :permission_level, default: 0, null: false
      t.datetime :expires_at
      t.timestamps
    end

    add_index :shared_accesses, %i[account_id shareable_type shareable_id], name: "index_shared_accesses_on_account_share"
    add_index :shared_accesses, [:shared_with_account_id], name: "index_shared_accesses_on_shared_with"
  end
end
