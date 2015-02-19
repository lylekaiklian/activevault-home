# This class represents a single Test Case. 
# A test case contains multiple lines of Test Case Items.
# For simplicity, a test case item is a line of comma-separated value.

require 'aws-sdk'

class TreasureTestCase
    
    attr_accessor :items
    attr_reader :sqs_url
    attr_reader :target_machine
    
    def initialize(params={}) 
        self.items = []
        
        get_from_file(params[:file]) if !params[:file].blank?
        
        #Remove hardcoded-ness later. Needs just to present this thing.
        @sqs_url = params[:sqs_url] || "https://sqs.ap-southeast-1.amazonaws.com/119554206391/lost_treasure" 
        @target_machine = params[:target_machine] || "adelfa"
        
    end 
    
    #Parse incoming CSV file
    def get_from_file(file)
    end
    
    #Push to SQS. Push it line by line. 
    def push_to_sqs
        sqs = Aws::SQS::Client.new(region: 'ap-southeast-1')
        output =""
        sqs.list_queues.each do |resp|
            output += resp.data.to_json + "\n"
        end
    
        

        return output
    end
    
     

     
end
