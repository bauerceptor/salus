class CreateKarmaPoints < ActiveRecord::Migration[8.1]
  def change
    create_table :karma_points, id: :uuid do |t|
      t.references :account, null: false, type: :uuid, foreign_key: true
      t.references :post, null: false, type: :uuid, foreign_key: true
      t.string :reaction_type, null: false
      t.integer :points, null: false
      t.timestamps
    end

    add_index :karma_points, :account_id
    add_index :karma_points, :post_id
    add_index :karma_points, %i[account_id post_id]
  end
end
