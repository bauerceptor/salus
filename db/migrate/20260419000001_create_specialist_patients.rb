class CreateSpecialistPatients < ActiveRecord::Migration[8.1]
  def change
    create_table :specialist_patients, id: :uuid do |t|
      t.references :specialist, foreign_key: { to_table: :users }, type: :uuid, null: false
      t.references :account, foreign_key: true, type: :uuid, null: false
      t.string :status, default: "pending", null: false
      t.string :relationship_type, default: "consulting", null: false
      t.text :notes
      t.timestamps
    end

    add_index :specialist_patients, %i[specialist_id account_id], unique: true
    add_index :specialist_patients, :status
  end
end
