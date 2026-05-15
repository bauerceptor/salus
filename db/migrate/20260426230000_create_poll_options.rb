class CreatePollOptions < ActiveRecord::Migration[8.1]
  def change
    create_table :poll_options, id: :uuid do |t|
      t.references :post, null: false, foreign_key: true, type: :uuid
      t.string :option_text, null: false
      t.integer :vote_count, default: 0

      t.timestamps
    end

    add_index :poll_options, :post_id
  end
end
