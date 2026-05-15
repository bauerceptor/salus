class CreateSpecialistMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :specialist_messages, id: :uuid do |t|
      t.references :specialist, foreign_key: { to_table: :users }, type: :uuid, null: false
      t.references :account, foreign_key: true, type: :uuid, null: false
      t.references :specialist_recommendation, foreign_key: true, type: :uuid
      t.string :sender_type, null: false
      t.string :subject, null: false
      t.text :body, null: false
      t.references :parent, foreign_key: { to_table: :specialist_messages }, type: :uuid
      t.boolean :is_read, default: false, null: false
      t.timestamps
    end

    add_index :specialist_messages, %i[specialist_id account_id]
    add_index :specialist_messages, :sender_type
    add_index :specialist_messages, :is_read
  end
end
