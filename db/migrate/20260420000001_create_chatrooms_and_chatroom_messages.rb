class CreateChatroomsAndChatroomMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :chatrooms, id: :uuid do |t|
      t.references :account1, null: false, foreign_key: { to_table: :accounts }, type: :uuid
      t.references :account2, null: false, foreign_key: { to_table: :accounts }, type: :uuid
      t.timestamps
    end

    add_index :chatrooms, [:account1_id, :account2_id], unique: true

    create_table :chatroom_messages, id: :uuid do |t|
      t.text :body
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :chatroom, null: false, foreign_key: true, type: :uuid
      t.integer :message_type, default: 0
      t.json :reactions, default: {}
      t.datetime :read_at
      t.bigint :reply_to_message_id
      t.timestamps
    end

    add_index :chatroom_messages, :message_type
    add_index :chatroom_messages, :read_at

    create_table :chatroom_participants, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :chatroom, null: false, foreign_key: true, type: :uuid
      t.datetime :last_read_at
      t.timestamps
    end

    add_index :chatroom_participants, [:account_id, :chatroom_id], unique: true

    add_column :accounts, :online_status, :integer, default: 0
    add_column :accounts, :last_seen_at, :datetime
    add_column :accounts, :typing_in_chatroom_id, :uuid
  end
end