class CreateCaregivers < ActiveRecord::Migration[8.1]
  def change
    create_table :caregivers, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :caregiver_account, foreign_key: { to_table: :accounts }, type: :uuid
      t.string :relationship, null: false
      t.boolean :can_view_medications, default: true, null: false
      t.boolean :can_view_measurements, default: true, null: false
      t.boolean :can_view_diseases, default: true, null: false
      t.boolean :notify_on_missed_dose, default: true, null: false
      t.boolean :notify_on_low_adherence, default: true, null: false
      t.boolean :notify_on_abnormal_measurement, default: false, null: false
      t.boolean :is_accepted, default: false, null: false
      t.timestamps
    end

    add_index :caregivers, %i[account_id is_accepted]
    add_index :caregivers, %i[caregiver_account_id is_accepted]
  end
end
