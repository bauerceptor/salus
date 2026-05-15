class CreateSpecialistRecommendations < ActiveRecord::Migration[8.1]
  def change
    create_table :specialist_recommendations, id: :uuid do |t|
      t.references :specialist, foreign_key: { to_table: :users }, type: :uuid, null: false
      t.references :account, foreign_key: true, type: :uuid, null: false
      t.references :medication, foreign_key: true, type: :uuid
      t.references :treatment, foreign_key: true, type: :uuid
      t.string :recommendation_type, null: false
      t.string :status, default: "pending", null: false
      t.string :name, null: false
      t.string :dosage
      t.text :notes
      t.timestamps
    end

    add_index :specialist_recommendations, %i[specialist_id account_id]
    add_index :specialist_recommendations, :status
  end
end
