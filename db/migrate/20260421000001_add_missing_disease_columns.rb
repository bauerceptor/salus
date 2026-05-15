class AddMissingDiseaseColumns < ActiveRecord::Migration[8.1]
  def change
    add_column :diseases, :diagnosed_at, :date
    add_column :diseases, :diagnosed_by_hp, :boolean, default: false
    add_column :diseases, :severity, :integer, default: 1, null: false
    add_column :diseases, :color, :string, default: "", null: false

    change_column_null :diseases, :name, true
  end
end
