require 'dongle'
require 'lost_treasure_exceptions/method_not_yet_implemented_exception'

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
  end
  
  def number(&block)
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
  end
  
  def set_number(number, &block)
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
  end
  
  
  def model
    @gsm_modem.execute "AT+CGMM"
  end
    
  def send_message(number, message)
    raise LostTreasureExceptions::MethodNotYetImplementedException  
    #response = @gsm_modem.execute "AT+CMGF=1" do |response|
    #  response += @gsm_modem.execute %Q(AT+CMGS="#{number}"\r\n#{message}\x1a)
    #end    
    #response
  end
  
  def messages
    @gsm_modem.execute %Q(AT+CMGL="ALL")
  end
  
  def delete_message(index, &block)
    @gsm_modem.execute "AT+CMGF=1" do |response|
      puts "dongle.delete_message: deleting message #{index}"
      @gsm_modem.execute %Q(AT+CMGD=#{index}) do |response|
        
        #Allow further chaining
        if !block.nil?
          block.call(response)
        else
          response
        end     
      end
    end
  end
  
  def delete_all_messages(&block)
    raise LostTreasureExceptions::MethodNotYetImplementedException  
    #@gsm_modem.execute "AT+CMGF=1" do |response|
    #  puts "dongle.delete_all_messages deleting ALL messages"
    #  @gsm_modem.execute %Q(AT+CMGD=0,4) do |response|
        
        #Allow further chaining
    #    if !block.nil?
    #      block.call(response)
    #    else
    #      response
    #    end      
    #  end
    #end
  end 

=begin  
  def delete_all_messages(start_index = 1, &block)
    #Assume sim card has 30 messages.
    upper_limit = 30 
    
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
=end
  
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
        matches = /^\+CMTI: "[^"]*",(\d+)/.match(input)
        if !matches.nil?
          message_index = matches[1]
          
          #This is considered as one message
          return message_index, 1
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

      message_index = message_index_array.shift
      
      @gsm_modem.execute %Q(AT+CMGR=#{message_index.to_i}) do |response|
        
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
    puts "Bulaga"
    #send_message(222, "BAL")
    
    #Do not wait any further if one +CMTI has been encountered
    #wait_for_new_message(waiting_timeout, 1) do |response|
    #  matches = /Your balance as of (\d+\/\d+\/\d+ \d+:\d+) is (P\d+\.\d+) valid til (\d+\/\d+\/\d+ \d+:\d+) w\/ (\d+) FREE txts. Pls note that system time may vary from the time on ur phone\./.match(response[:message])
    #  return {timestamp: matches[1], balance: matches[2], validity: matches[3], free_text: matches[4]}
    #end
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
