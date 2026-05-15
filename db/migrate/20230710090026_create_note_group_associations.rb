class CreateNoteGroupAssociations < ActiveRecord::Migration[8.1]
  def change
    create_table :note_group_associations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :note, null: false, type: :uuid
      t.references :note_group, null: false, type: :uuid
      t.timestamps
    end
    add_index :note_group_associations, %i[note_id note_group_id], unique: true
  end
end
