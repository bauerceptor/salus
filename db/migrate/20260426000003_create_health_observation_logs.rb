class CreateHealthObservationLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :health_observation_logs, id: :uuid do |t|
      t.references :account, type: :uuid, null: false, foreign_key: true
      t.references :specialist, type: :uuid, foreign_key: { to_table: :users }, null: true
      t.string :observation_type, null: false
      t.integer :confidence_level, default: 0
      t.jsonb :evidence, default: []
      t.string :triggered_by
      t.integer :status, default: 0
      t.integer :observation_count, default: 1
      t.timestamps
    end

    add_index :health_observation_logs, :account_id, if_not_exists: true
    add_index :health_observation_logs, :observation_type, if_not_exists: true
    add_index :health_observation_logs, :status, if_not_exists: true
  end
end
