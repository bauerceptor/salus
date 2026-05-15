class CreatePollVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :poll_votes, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :poll_option, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :poll_votes, :account_id
    add_index :poll_votes, :poll_option_id
    add_index :poll_votes, %i[account_id poll_option_id], unique: true
  end
end
