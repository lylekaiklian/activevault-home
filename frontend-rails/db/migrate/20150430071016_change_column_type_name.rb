class ChangeColumnTypeName < ActiveRecord::Migration
  def change
    rename_column :scenarios, :type, :test_type
  end
end
