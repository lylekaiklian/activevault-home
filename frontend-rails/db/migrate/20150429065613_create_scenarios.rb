class CreateScenarios < ActiveRecord::Migration
  def change
    create_table :scenarios do |t|
      t.string :batch
      t.integer :sequence_no
      t.integer :ref_no
      t.datetime :test_date
      t.text :description
      t.string :keyword
      t.string :a_number
      t.string :b_number
      t.text :expected_result
      t.datetime :time_sent
      t.datetime :time_received
      t.integer :beginning_balance
      t.integer :ending_balance
      t.integer :amount_charged
      t.text :actual_result
      t.boolean :pass_or_fail
      t.text :remarks
      t.string :ussd_command
      t.string :ussd_number
      t.string :type
    end
  end
end
