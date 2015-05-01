class RenameColumnsInScenarios < ActiveRecord::Migration
  def change
    rename_column :scenarios, :a_number, :sender
    rename_column :scenarios, :b_number, :recipient
  end
end
