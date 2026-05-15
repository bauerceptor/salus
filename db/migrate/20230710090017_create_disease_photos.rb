class CreateDiseasePhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :disease_photos, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :disease, null: false, type: :uuid
      t.string :caption, limit: 255
      t.text :photo_data
      t.timestamps
    end
  end
end
