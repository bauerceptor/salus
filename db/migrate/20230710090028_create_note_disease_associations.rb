class CreateNoteDiseaseAssociations < ActiveRecord::Migration[8.1]
  def change
    create_table :note_disease_associations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :note, null: false, type: :uuid
      t.references :disease, null: false, type: :uuid
      t.timestamps
    end
    add_index :note_disease_associations, %i[note_id disease_id], unique: true
  end
end
