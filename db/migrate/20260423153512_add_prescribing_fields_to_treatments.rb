class AddPrescribingFieldsToTreatments < ActiveRecord::Migration[8.1]
  def change
    add_column :treatments, :specialist_recommendation_id, :uuid
    add_column :treatments, :source, :string

    add_index :treatments, :specialist_recommendation_id
    add_index :treatments, :source
  end
end
