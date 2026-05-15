class MakeAccountsEmailNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :accounts, :email, true
  end
end
