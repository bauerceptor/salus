class CreateNoteGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :note_groups, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :account, null: false, type: :uuid
      t.string :name, limit: 255
      t.timestamps
    end
  end
end
