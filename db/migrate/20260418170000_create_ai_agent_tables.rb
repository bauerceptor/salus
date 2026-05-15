class CreateAiAgentTables < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_agent_conversations, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.string :title, default: "New Chat"
      t.timestamps
    end

    create_table :ai_agent_messages, id: :uuid do |t|
      t.references :conversation, null: false, foreign_key: { to_table: :ai_agent_conversations }, type: :uuid
      t.string :role, null: false
      t.text :content, null: false
      t.json :attachments, default: {}
      t.timestamps
    end

    add_index :ai_agent_conversations, %i[account_id updated_at]
    add_index :ai_agent_messages, %i[conversation_id created_at]
  end
end
