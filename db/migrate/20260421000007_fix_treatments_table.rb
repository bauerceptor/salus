class FixTreatmentsTable < ActiveRecord::Migration[8.1]
  def change
    add_column :treatments, :title, :string, default: "", null: false unless column_exists?(:treatments, :title)
    unless column_exists?(:treatments, :effectiveness)
      add_column :treatments, :effectiveness, :integer, default: 0, null: false
    end
    unless column_exists?(:treatments, :is_finished)
      add_column :treatments, :is_finished, :boolean, default: false, null: false
    end

    if column_exists?(:treatments, :name) && !column_exists?(:treatments, :title)
      rename_column :treatments, :name, :title
    end

    begin
      change_column_null :treatments, :title, true
    rescue StandardError
      nil
    end
  end
end
