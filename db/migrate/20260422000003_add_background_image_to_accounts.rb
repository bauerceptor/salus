class AddBackgroundImageToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :background_data, :text
    add_column :accounts, :background_position, :string, default: "center"
  end
end
