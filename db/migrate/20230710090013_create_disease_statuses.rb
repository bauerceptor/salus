class CreateDiseaseStatuses < ActiveRecord::Migration[8.1]
  def change
    create_table :disease_statuses, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :disease, null: false, type: :uuid
      t.string :status, null: false, default: ""
      t.text :notes
      t.timestamps
    end
  end
end
