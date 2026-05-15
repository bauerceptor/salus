class CreateMedications < ActiveRecord::Migration[8.1]
  def change
    create_table :medications, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :disease, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :dosage, null: false
      t.string :frequency, null: false
      t.text :instructions
      t.date :start_date
      t.date :end_date
      t.boolean :is_active, default: true, null: false
      t.text :notes
      t.timestamps
    end

    add_index :medications, %i[account_id is_active]
  end
end
