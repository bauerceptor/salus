class CreateTreatments < ActiveRecord::Migration[8.1]
  def change
    create_table :treatments, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :account, null: false, type: :uuid
      t.string :name, null: false, default: ""
      t.text :description
      t.string :status, default: "active"
      t.date :start_date
      t.date :end_date
      t.timestamps
    end
  end
end
