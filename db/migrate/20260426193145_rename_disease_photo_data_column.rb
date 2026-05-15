class RenameDiseasePhotoDataColumn < ActiveRecord::Migration[8.1]
  def change
    rename_column :disease_photos, :photo_data, :image_data
  end
end
