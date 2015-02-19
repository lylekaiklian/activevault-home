class LostTreasureController < ApplicationController
  def index
  end
  
  #Process incoming CSV file, and queue it to SQS
  def submit
      treasure_test_case = TreasureTestCase.new  
      treasure_test_case.push_to_sqs
  end
  
end
 
 