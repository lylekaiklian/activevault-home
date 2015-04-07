#This queue connects with the web front-end to collect commands from the user
require 'jar/aws-java-sdk-1.9.20.1.jar'
require 'set'

class TreasureQueue
  def unpack
    import('com.amazonaws.services.sqs.AmazonSQSClient')
    
    #Refactor: remove hard-coded url
    queue_url = "https://sqs.ap-southeast-1.amazonaws.com/119554206391/lost_treasure"
    sqs = AmazonSQSClient.new    
    messages_sorted = {};
    batches = Set.new [];
    message_index = {};
    
    puts "Waiting for messages..."
  

    loop do
      begin
        
          messages = sqs.receive_message(queue_url).get_messages
        
          messages.each do |message|
            receipt_handle = message.get_receipt_handle
            message_body = JSON.parse(message.get_body, {symbolize_names: true})
            puts "Batch #{message_body[:batch]}, Sequence #{message_body[:sequence_no]} receieved."
            
            batches << message_body[:batch].to_s.to_sym 
            messages_sorted[message_body[:batch].to_s.to_sym] = {} if messages_sorted[message_body[:batch].to_s.to_sym].nil?
            messages_sorted[message_body[:batch].to_s.to_sym][message_body[:sequence_no]] = message_body
            
            sqs.delete_message(queue_url, receipt_handle)
          end
          
          #Keep track of indeces for every batch
          batches.each do |current_batch|          
            
            message_index[current_batch] = 1 if message_index[current_batch].nil?
            
            loop do
              if !messages_sorted[current_batch][message_index[current_batch]].nil?
                 puts "Processing Batch #{current_batch}, Sequence #{message_index[current_batch]}..."
                 mock_process(messages_sorted[current_batch][message_index[current_batch]])
                 message_index[current_batch] += 1
                 next
              else
                #Wait for the next index in the queue
                break 
              end 
            end
          end
        
        sleep 0.10
          
      rescue StandardError => ex
        puts "Ignoring #{ex.class.name} - #{ex.message}"
      end  
                   
    end
    

  end
  
  def mock_process(request)
    
    response = request.dup
    response[:time_sent] = "09:17AM"
    response[:time_received] = "09:19AM"
    response[:beginning_balance] = 37
    response[:ending_balance] = 35.50
    response[:amount_charged] = 2.50
    response[:actual_result] = "I hope senpai notices me."
    response[:pass_or_fail] = "pass"
    response[:remarks] = "OK"
    
    
    puts "===REQUEST==="
    puts request.to_json
    puts "===RESPONSE==="
    puts response.to_json
  end
  
end