class AddColumnsToScenarios < ActiveRecord::Migration
  def change
    add_column :scenarios, :operation, :string
    add_column :scenarios, :expected_charge, :string
    add_column :scenarios, :run_time, :string
    add_column :scenarios, :number_of_tries, :integer
    add_column :scenarios, :condition, :string
    add_column :scenarios, :status, :string
  end
end
