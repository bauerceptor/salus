class CreateNoteTagAssociations < ActiveRecord::Migration[8.1]
  def change
    create_table :note_tag_associations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :note, null: false, type: :uuid
      t.references :note_tag, null: false, type: :uuid
      t.timestamps
    end
    add_index :note_tag_associations, %i[note_id note_tag_id], unique: true
  end
end
