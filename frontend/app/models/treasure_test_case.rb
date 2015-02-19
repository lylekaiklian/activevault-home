# This class represents a single Test Case. 
# A test case contains multiple lines of Test Case Items.
# For simplicity, a test case item is a line of comma-separated value.

require 'aws-sdk'

class TreasureTestCase
    
    #attr_reader :sqs_url
    #attr_reader :target_machine
    
    def initialize(params={}) 
        @items = []
        
        @sqs = Aws::SQS::Client.new(region: 'ap-southeast-1')
        
        get_from_file(params[:file_content]) if !params[:file_content].blank?
        
        #Remove hardcoded-ness later. Needs just to present this thing.
        @sqs_url = params[:sqs_url] || "https://sqs.ap-southeast-1.amazonaws.com/119554206391/lost_treasure" 
        @target_machine = params[:target_machine] || "adelfa"
        
        puts @items.inspect
        
    end 
    
    #Parse incoming CSV file
    def get_from_file(file_content)
        file_items = file_content.split("\n")
        file_items.each do |i|
            @items << i
        end
    end
    
    #Push to SQS. Push it line by line. 
    def push_to_sqs
        batch = Time.now.to_i
        @items.each_with_index do |test_item, order_id|
            response = @sqs.send_message(queue_url: @sqs_url, 
                message_body: {
                    target_machine: @target_machine,
                    batch: batch,
                    order_id: order_id + 1,
                    data: test_item
                    }.to_json)
            #TODO: double check if SQS receives the message correcty via MD5 Checking
        end
        
    end
    
     

     
end
