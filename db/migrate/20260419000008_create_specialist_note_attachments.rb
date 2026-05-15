class CreateSpecialistNoteAttachments < ActiveRecord::Migration[8.1]
  def change
    create_table :specialist_note_attachments, id: :uuid do |t|
      t.references :specialist_note, null: false, foreign_key: true, type: :uuid
      t.string :file_type, limit: 100
      t.string :file_url, limit: 500
      t.string :filename, limit: 255
      t.timestamps
    end
  end
end
