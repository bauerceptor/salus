class CreateHealthAgentMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :health_agent_messages, id: :uuid do |t|
      t.references :conversation, type: :uuid, null: false, foreign_key: { to_table: :health_agent_conversations }
      t.integer :role, null: false, default: 0
      t.text :content, null: false
      t.jsonb :attachments, default: []
      t.timestamps
    end

    add_index :health_agent_messages, :conversation_id, if_not_exists: true
    add_index :health_agent_messages, :role, if_not_exists: true
  end
end
