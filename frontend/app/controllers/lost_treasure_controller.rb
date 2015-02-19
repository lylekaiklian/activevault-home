class LostTreasureController < ApplicationController
  def index
  end
  
  #Process incoming CSV file, and queue it to SQS
  def submit
      test_case_input = params[:test_case_input].read
      treasure_test_case = TreasureTestCase.new(file_content: test_case_input)  
      @output = treasure_test_case.push_to_sqs
  end
  
end
 
 