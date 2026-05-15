class CreateClinicalDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :clinical_documents, id: :uuid do |t|
      t.references :account, type: :uuid, null: false, foreign_key: true
      t.references :uploaded_by, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.string :document_type, null: false
      t.jsonb :file_data, default: {}
      t.text :parsed_content
      t.boolean :ai_processed, default: false
      t.timestamps
    end

    add_index :clinical_documents, :document_type, if_not_exists: true
    add_index :clinical_documents, :account_id, if_not_exists: true
    add_index :clinical_documents, :ai_processed, if_not_exists: true
  end
end
