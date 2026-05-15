class AddDiseaseCategoryToDiseases < ActiveRecord::Migration[7.1]
  def change
    add_reference :diseases, :disease_category, type: :uuid, foreign_key: true
  end
end
