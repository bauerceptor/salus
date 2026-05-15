class CreateChatTables < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations, id: :uuid, &:timestamps

    create_table :conversation_participants, id: :uuid do |t|
      t.references :conversation, null: false, foreign_key: true, type: :uuid
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.datetime :last_read_at
      t.timestamps
    end

    add_index :conversation_participants, %i[account_id conversation_id], unique: true

    create_table :messages, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :conversation, null: false, foreign_key: true, type: :uuid
      t.text :body
      t.string :message_type, default: "text", null: false
      t.string :attachment_url
      t.string :attachment_type
      t.integer :duration # for voice messages in seconds
      t.timestamps
    end

    add_index :messages, %i[conversation_id created_at]
  end
end
