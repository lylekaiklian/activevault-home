#This queue connects with the web front-end to collect commands from the user
require 'jar/aws-java-sdk-1.9.20.1.jar'

class TreasureQueue
  def unpack
    import('com.amazonaws.services.sqs.AmazonSQSClient')
    
    #Refactor: remove hard-coded url
    queue_url = "https://sqs.ap-southeast-1.amazonaws.com/119554206391/lost_treasure"
    sqs = AmazonSQSClient.new    
    messages_sorted = [];
    message_index = 1;
    
    loop do
      #puts "Waiting for messages..."
      messages = sqs.receive_message(queue_url).get_messages
    
      messages.each do |message|
        receipt_handle = message.get_receipt_handle
        message_body = JSON.parse(message.get_body, {symbolize_names: true})
        puts "Sequence #{message_body[:sequence_no]} receieved."
        messages_sorted[message_body[:sequence_no]] = message_body
        sqs.delete_message(queue_url, receipt_handle)
      end
      
      loop do
        if !messages_sorted[message_index].nil?
          puts "Processing sequence #{message_index}..."
          message_index += 1
          next
        else
          #Wait for the next index in the queue
          break 
        end 
      end
      
      
      
      sleep 0.10
      
      
    end
  end
end