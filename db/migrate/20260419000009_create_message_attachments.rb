class CreateMessageAttachments < ActiveRecord::Migration[8.1]
  def change
    create_table :message_attachments, id: :uuid do |t|
      t.references :message, null: false, foreign_key: true, type: :uuid
      t.string :file_type, limit: 100
      t.text :file_data
      t.string :filename, limit: 255
      t.string :content_type, limit: 100
      t.timestamps
    end
  end
end
