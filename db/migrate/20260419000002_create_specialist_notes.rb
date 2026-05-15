class CreateSpecialistNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :specialist_notes, id: :uuid do |t|
      t.references :specialist, foreign_key: { to_table: :users }, type: :uuid, null: false
      t.references :account, foreign_key: true, type: :uuid, null: false
      t.text :content, null: false
      t.string :note_type, default: "observation", null: false
      t.timestamps
    end

    add_index :specialist_notes, %i[specialist_id account_id]
  end
end
