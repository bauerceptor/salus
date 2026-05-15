class AddOtpFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :otp_secret, :string, if_not_exists: true
    add_column :users, :otp_backup_codes, :text, if_not_exists: true
    add_column :users, :otp_required_for_login, :boolean, default: false, null: false, if_not_exists: true
  end
end
