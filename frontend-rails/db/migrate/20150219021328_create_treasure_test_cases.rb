class CreateTreasureTestCases < ActiveRecord::Migration
  def change
    create_table :treasure_test_cases do |t|

      t.timestamps null: false
    end
  end
end
