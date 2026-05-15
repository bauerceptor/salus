class AddApprovalFieldsToTreatments < ActiveRecord::Migration[7.1]
  def change
    add_column :treatments, :approval_status, :string, default: "pending", null: false
    add_column :treatments, :requested_at, :datetime
    add_column :treatments, :approved_at, :datetime
    add_column :treatments, :approved_by_id, :uuid
    add_column :treatments, :is_hidden, :boolean, default: false, null: false
    add_column :treatments, :hidden_at, :datetime

    add_index :treatments, :approval_status
    add_index :treatments, %i[account_id approval_status]
  end
end
