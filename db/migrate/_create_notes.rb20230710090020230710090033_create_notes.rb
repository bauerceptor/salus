class CreateNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :notes, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :account, null: false, type: :uuid
      t.string :title, limit: 255
      t.text :content
      t.string :note_type, limit: 50, default: "general"
      t.timestamps
    end
  end
end
