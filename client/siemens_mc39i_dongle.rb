require 'dongle'

class SiemensMc39iDongle < Dongle
    
  def device_info(&block)
    @gsm_modem.execute "ATI" do |response|
      if !block.nil?
        "#{block.call(response)}"
      end     
      response
    end
  end
  
  def manufacturer
    @gsm_modem.execute "AT+CGMI"
  end
  
  def imei(&block)
    raise LostTreasureExceptions::MethodNotYetImplementedException
=begin      
    @gsm_modem.execute "ATI" do |response|
      matches = /IMEI:[\s]*(.*)[\r]*[\s]*/.match(response)
      if !matches.nil?
        response = matches[1]
      else
        response = ""
      end
      
      if !block.nil?
        return "#{block.call(response)}"
      else
        return response
      end     
      
    end
=end   
  end
  
  def number(&block)
    raise LostTreasureExceptions::MethodNotYetImplementedException
=begin
    @gsm_modem.execute "AT+CNUM" do |response|
      matches = /\+CNUM: "[^"]*","([^"]*)",\d+/.match(response)
      if !matches.nil?
        response = matches[1]
      else
        response = ""
      end
      
      if !block.nil?
        "#{block.call(response)}"
      else
        response
      end 
    end
=end
  end
  
  def set_number(number, &block)
    raise LostTreasureExceptions::MethodNotYetImplementedException
=begin    
    @gsm_modem.execute %Q(AT+CPBS="ON") do |response1|
        response1 += @gsm_modem.execute %Q(AT+CPBW=1,"#{number}",129,"My Number") do |response2|        
          
          #Allow further chaining
          if !block.nil?
            #{block.call(response2)}"
          else
            response2
          end 
        end
      response1
    end
=end 
  end
  
  
  def model
    @gsm_modem.execute "AT+CGMM"
  end
    
  def send_message(number, message)
    # ATE0                Disable echo
    # AT+CMGF=1           Set SMS mode to "Text Mode"
    # AT+CPMS="MT"        Use the machine as storage for SMS
    # AT+CNMI=3,1         Enable Unsolicited Result Code for SMS (via +CMTI)
    # AT+CMGW=222         Write SMS to memory. Returns +CMGW: <index>, to be used by +CMSS
    # AT+CMSS=1           Send the SMS.
    @gsm_modem.execute %Q(ATE0) do |response|
      @gsm_modem.execute %Q(AT+CMGF=1;+CNMI=3,1;+CPMS="ME") do |response|
        @gsm_modem.execute("AT+CMGW=#{number}", "#{message}\x1A") do |response|          
          input = response
          
          #Get the index from the last operation
          matches = /\+CMGW: (\d+)/.match(input)
          
          if !matches.nil?
            index = matches[1]
          else 
            raise LostTreasureExceptions::SmsSendingFailedException.new("Error at +CMGW")
          end
          
          @gsm_modem.execute("AT+CMSS=#{index}") do |response|
            input = response
            matches = /\+CMSS: (\d+)/.match(input)
            if !matches.nil?
              index = matches[1]
            else 
              raise LostTreasureExceptions::SmsSendingFailedException.new("Error at +CMSS")
            end
            
            {
              success: true,
              message: message,
              number: number
            }
            
          end
        end
      end
    end

  end
  
  def messages
    @gsm_modem.execute %Q(AT+CMGL="ALL")
  end
  
  def delete_message(index, &block)
    puts "dongle.delete_message: deleting message #{index}"
    #Ensure space in both SM and MT. -_-
    @gsm_modem.execute %Q(AT+CMGF=1;+CPMS="SM";+CMGD=#{index}) do |response|
      @gsm_modem.execute %Q(AT+CMGF=1;+CPMS="MT";+CMGD=#{index}) do |response|          
        #Allow further chaining
        if !block.nil?
          block.call(response)
        else
          response
        end
      end     
    end
  end
  
  #MC39i has no built-in delete all message, so we do recursive deletion. 
  def delete_all_messages(start_index = 1, &block)
    
    upper_limit = 10 
    
    if start_index >= upper_limit
      #Base case section
      if !block.nil?
        puts "dongle.delete_all_messages: invoking block"
        block.call
      end
    else
      #Recursive section
      delete_message(start_index) do
        delete_all_messages(start_index + 1) do
          block.call if !block.nil?
        end
      end     
    end
  end

  
=begin  
  def wait_for_new_message(&block)
    @gsm_modem.wait_for(/^\+CMTI/) do |response|
      matches = /^\+CMTI: "[^"]*",(\d+)/.match(response)
      message_index = matches[1]
      
      @gsm_modem.execute %Q(AT+CMGR=#{message_index}) do |response|
        
        matches = /\+CMGR: "([^"]*)","([^"]*)",,"([^"]*)"\r\n(.*)\r\n\r\n/m.match(response)
        status = matches[1]
        sender = matches[2]
        timestamp = matches[3]
        message = matches[4]
        
        return_value = { status: status, 
            sender: sender,
            timestamp: timestamp,
            message:message
          }
        if !block.nil?
          return block.call(return_value)
        else
          return return_value
        end
      end
    end   
  end
=end

  #Use the listener implementation for all
=begin  
  def wait_for_new_message(waiting_timeout = 10, &block)
    wait_for_new_message_via_listeners(waiting_timeout) do |response|
      if !block.nil?
        block.call(response)
      else
        response
      end
    end
  end
=end
  def wait_for_new_message(waiting_timeout = 10, waiting_counter = 999999999999, &block)
    result_message_index_array = @gsm_modem.wait_for(waiting_timeout, waiting_counter, [
      (lambda do |input|
        matches = /^\+CMTI: "([^"]*)",(\d+)/.match(input)
        if !matches.nil?
          message_storage = matches[1]
          message_index = matches[2]
          
          #This is considered as one message
          return {message_index: message_index, message_storage: message_storage}, 1
        else
          return nil
        end
      end)
    ])
    
    puts "dongle.wait_for_new_message: result_message_index_array: #{result_message_index_array.to_json}"
    
    # puts 
    # Process collected messages here.
    # Read the incoming messages recursively    
    
    read_lambda = lambda do |message_index_array|

      return {message: ""} if message_index_array.empty?

      message_structure = message_index_array.shift
      message_index = message_structure[:message_index]
      message_storage = message_structure[:message_storage]
      
      
      puts "dongle.wait_for_new_message: Reading message #{message_storage}, #{message_index}"
      
      @gsm_modem.execute %Q(AT+CPMS="#{message_storage}";+CMGR=#{message_index.to_i}) do |response|
        
        matches = /\+CMGR: "([^"]*)","([^"]*)",,"([^"]*)"\r\n(.*)\r\n\r\n/m.match(response)
        status = matches[1]
        sender = matches[2]
        timestamp = matches[3]
        message = matches[4]
        
        #Cleanup message. Somehow MC39i has a weird header added to some messages
        message_match = /\u0005\u0000.*\u0000(.*)/m.match(message)
        if !message_match.nil?
          message = message_match[1]
        end
        
        return_value = { status: status, 
            sender: sender,
            timestamp: timestamp,
            message:message
          }
        
        next_message = read_lambda.call(message_index_array)
        
        #concatenate message, assume sender is the same
        return_value[:message] += next_message[:message]

        return_value
      end
    end
    
    #Give ability to chain this command
    if !block.nil?
      block.call(read_lambda.call(result_message_index_array))
    else
      read_lambda.call(result_message_index_array)
    end
  end
  
  def balance_inquiry(waiting_timeout = 10)
    #puts "Bulaga"
    send_message(222, "BAL")
    
    #Do not wait any further if one +CMTI has been encountered
    wait_for_new_message(waiting_timeout, 1) do |response|
      matches = /Your balance as of (\d+\/\d+\/\d+ \d+:\d+) is (P\d+\.\d+) valid til (\d+\/\d+\/\d+ \d+:\d+) w\/ (\d+) FREE txts. Pls note that system time may vary from the time on ur phone\./.match(response[:message])
      return {timestamp: matches[1], balance: matches[2], validity: matches[3], free_text: matches[4]}
    end
  end
  
  
  def messages_old
    messages = @gsm_modem.execute %Q(AT+CMGL="ALL")
    messages = scrub messages
      
    message_array = []
    message_array_item = {}
    messages.split("\r\n").each_with_index do |line, index|
      message_index = index / 2
      
      if index % 2 == 0   # header
        
        x, header = line.split("CMGL:")
        message_index, status, carrier, x, smsdate, smstime = header.split(",")
        message_array_item = {
          index: message_index.to_i,
          status: status.sub(/^"(.*)"$/, '\1'),
          carrier: carrier.sub(/^"(.*)"$/, '\1'),
          smsdate: smsdate.sub(/^"(.*)/, '\1'),
          smstime: smstime.sub(/"(.*)$/, '\1')
        }
      else        # message body
        message_array_item[:message] = line
        message_array[message_index] = message_array_item
      end
    end
    
    message_array.sort!{|x,y| y[:index] <=> x[:index]}.to_json
    #messages
  end
  
end
