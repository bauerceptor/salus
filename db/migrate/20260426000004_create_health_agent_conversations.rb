class CreateHealthAgentConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :health_agent_conversations, id: :uuid do |t|
      t.references :account, type: :uuid, null: false, foreign_key: true
      t.integer :persona, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.timestamps
    end

    add_index :health_agent_conversations, :account_id, if_not_exists: true
    add_index :health_agent_conversations, :persona, if_not_exists: true
    add_index :health_agent_conversations, :status, if_not_exists: true
  end
end
