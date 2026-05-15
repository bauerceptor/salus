class CreateBehaviorSequences < ActiveRecord::Migration[8.1]
  def change
    create_table :behavior_sequences, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.string :sequence_type, null: false
      t.json :events, default: []
      t.integer :adherence_score, default: 100
      t.json :metadata, default: {}
      t.datetime :analyzed_at
      t.timestamps
    end

    add_index :behavior_sequences, %i[account_id sequence_type]
    add_index :behavior_sequences, %i[account_id adherence_score]
  end
end
