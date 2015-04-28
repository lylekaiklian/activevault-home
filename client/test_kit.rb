require 'dongle'
require 'java'
require 'jar/aws-java-sdk-1.9.20.1.jar'
require 'jar/commons-logging-1.2.jar'
require 'jar/jackson-databind-2.3.1.jar'
require 'jar/jackson-core-2.5.0.jar'
require 'jar/jackson-annotations-2.5.0.jar'
require 'jar/httpcore-4.4.jar'
require 'jar/httpclient-4.4.jar'
require 'yaml'
require 'bigdecimal'
require 'lost_treasure_exceptions/gsm_timeout_exceeded_exception'

##
# Here lies the promo codes we humans are all familiar with!
##
class TestKit

	attr_accessor :timeout_seconds

	def initialize(params={})
	
		@timeout_seconds = params[:timeout_seconds] || 60
				
		@sticks = YAML::load(File.read('ports.yml'))
		
		puts "Initializing Test Kit. Performing configuration sanity check..."
		@sticks.keys.each do |key|
		  dongle_type = @sticks[key][:dongle_type] || :default
			@sticks[key][:dongle_object] = DongleFactory.dongle(dongle_type, @sticks[key][:port])
			@sticks[key][:dongle_object].gsm_modem.timeout_seconds = @timeout_seconds
			puts "Information for #{key}:"
			puts @sticks[key]
		end
	end
	
	# This is the central method for this project 
	def send_and_must_receive(parameters)
	  
	  puts "test_kit.send_and_must_receive: invoked."
		stick = parameters[:stick]
		number = parameters[:number]
		message = parameters[:message]
		expected_result = parameters[:expected_result]
		charge = parameters[:charge]
		output = {}
		
		#deal with 29173292739
		if matches = number.match(/2\+([A-Z])/)			
			original_number = @sticks[matches[1].to_sym][:number]
			number = "2" + original_number[-10, original_number.length - 1]
		end
		
		dongle = @sticks[stick.to_sym][:dongle_object]
		
		#clean dongle
		puts "test_kit.send_and_must_receive: Cleaning up dongle."
		dongle.delete_all_messages do
		
  		#but first, we do a balance inquiry
  		puts "test_kit.send_and_must_receive: Checking initial balance..."
  		initial_balance = nil
  		initial_balance_response = dongle.balance_inquiry(60)		
  		initial_balance =  initial_balance_response[:balance].gsub(/[^\.0-9]/, "").to_f if !initial_balance_response.nil?
  		puts "test_kit.send_and_must_receive: Initial balance: #{initial_balance}"
  		
  		time_sent = Time.now
  		puts "test_kit.send_and_must_receive: sending message #{message} to #{number}"
  		dongle.send_message(number, message)
  		
  		# Either we wait for 2 minutes, or we wait for a certain number of SMS received.
  		# The number of expected SMS is number of characters divided by 160, rounded up.
  		max_character = 160
  		wait_time = 120
  		expected_number_of_messages = (expected_result.length.to_f / max_character).ceil
  		puts "test_kit.send_and_must_receive: waiting for #{wait_time} seconds OR #{expected_number_of_messages} SMS"
  		response = dongle.wait_for_new_message(wait_time, expected_number_of_messages)
  		
  		actual_result = response[:message]
  		
  		#Cheaters gonna cheat
  		# 
  		#response_message = expected_result
  		
  		time_received = Time.now
  		
  		#@sticks[stick.to_sym][:reply_number] = response[:sender]
  		#response_message = response[:message] 
  		puts "test_kit.send_and_must_receive: #{actual_result}"
  		
  		#Then we do a final balance inquiry to check
  		puts "test_kit.send_and_must_receive: Checking final balance..."
  		final_balance = nil
  		final_balance_response = dongle.balance_inquiry(60)
  		final_balance =  final_balance_response[:balance].gsub(/[^\.0-9]/, "").to_f if !final_balance_response.nil?
  		puts "test_kit.send_and_must_receive: Final balance: #{final_balance}"
  		
  		is_match = true
  		#is_match = !(/#{regex}/m =~ response_message).nil?
  		is_charged_correctly = true

  		#if !initial_balance.nil? && !final_balance.nil?
  		#	puts "Actual Charge: #{(BigDecimal.new(initial_balance.to_s) - BigDecimal.new(final_balance.to_s)).to_s("F")}"
  		#	is_charged_correctly = ((BigDecimal.new(initial_balance.to_s) - BigDecimal.new(final_balance.to_s)) == BigDecimal.new(charge.to_s))
  		#else
  		#	puts "Cannot calculate actual charge"
  		#end
  		
  		is_pass = is_match && is_charged_correctly
  		#is_pass = true
  		
  		    #delete all messages to cleanup
    #puts "Deleting all messages..."
    #dongle.delete_all_messages
    

    #Output
    output = {
      test_date: Time.now.strftime("%m/%d/%Y"),
      actual_result: actual_result,
      a_number: @sticks[stick.to_sym][:number],
      b_number: number,
      time_sent: time_sent.strftime("%I:%M %p"),
      time_received: time_received.strftime("%I:%M %p"),
      beginning_balance: "#{initial_balance}",
      ending_balance: "#{final_balance}",
      amount_charged: (!initial_balance.nil? && !final_balance.nil?) ? "#{initial_balance - final_balance}" : "ERROR",
      pass_or_fail: is_pass.to_s,
      remarks: "OK"
    }
   end
   
   puts "test_kit.send_and_must_receive: output: #{output.to_json}"   
   output
   
	end
	
	def ussd(parameters)

    puts "test_kit.ussd: invoked."
    stick = parameters[:stick]
    number = parameters[:number]
    commands = parameters[:commands]
    expected_result = parameters[:expected_result]
    
    dongle = @sticks[stick.to_sym][:dongle_object]

    actual_result = dongle.ussd(number: number, commands: commands)
    output = {
      actual_result: actual_result,
      pass_or_fail: "true",
      remarks: "OK"      
    }
	  
	end
	
	
	def must_be_charged(parameters)
		stick = parameters[0]
		amount = parameters[1]
		
		dongle = @sticks[stick.to_sym][:dongle_object]

		
		old_amount = @sticks[stick.to_sym][:balance]
		new_amount = dongle.balance_inquiry(15)[:balance].gsub(/[^\.0-9]/, "").to_f
		charge = old_amount - new_amount
		puts "Acutal charge: #{charge}"
		if amount.to_f == charge
			return true
		else
			return [false, "Must be charged #{amount.to_f}, actual charge is #{charge}"]
		end
	end
	
	def send_reply(parameters)
		stick = parameters[0]
		message = parameters[1]
		timeout = parameters[2].to_i #Deal with the timeout later
		
		reply_number = @sticks[stick.to_sym][:reply_number]
		dongle = @sticks[stick.to_sym][:dongle_object]
		dongle.send_message(reply_number, message)
		return nil
	end
	
	def must_receive(parameters)
		stick = parameters[0]
		sender = parameters[1]
		regex = parameters[2]
		
		dongle = @sticks[stick.to_sym][:dongle_object]
		response = dongle.wait_for_new_message(60)
		
		@sticks[stick.to_sym][:reply_number] = response[:sender]
		response_message = response[:message]
		puts "#{sender}: #{response_message}"
		
		# Tame Regex later
		#return (/#{regex}/ =~ response_message)
		return !response_message.nil? && sender == response[:sender]		

	end

	def close
		#Will clean. Sorry for the hackish code.
		#@sticks[:A][:dongle_object].close if !@sticks[:A][:dongle_object].nil?
		#@sticks[:B][:dongle_object].close if !@sticks[:B][:dongle_object].nil?
		
		@sticks.keys.each do |key|
			puts @sticks[key][:dongle_object].close
		end		
	end	
	
	def check_balance(parameters)
		stick = parameters[0]
		dongle = @sticks[stick.to_sym][:dongle_object]
		balance_response = dongle.balance_inquiry(15)
		balance =  balance_response[:balance].gsub(/[^\.0-9]/, "").to_f
		@sticks[stick.to_sym][:balance] = balance
		puts balance
		return nil #n/a
	end	
	
	def execute_line(line, out=nil)
	
		# Deal with white spaces
		return if line.strip.empty?
	
		# Deal with comments
		if line.strip[0] == "#"
			#puts "COMMENT: #{line}"
			#result = "**N/A**"
			#puts result + "\n\n"
			return
		end
						
		begin
			commands = line.split("\t")
			method = commands[1].strip
			parameters = Array.new(commands).map{|p| p.strip}
			result =  ""
			
			parameters.delete_at(1)
			puts "method: #{method}"
			puts "*** #{parameters.join("\n*** ")}"

			#puts self.class.name
			truth, reason, file_out_array = self.send(method, parameters)
			if truth.nil?
				result = "**N/A**"	
			elsif truth === true
				result = "**PASSED**"
			else
				result = "**FAILED** #{reason}"
			end
			
		rescue ThreadError => ex
			#puts ex.message
			result = "**FAILED** #{ex.message}"
		rescue NoMethodError => ex
			puts ex.message
			puts %Q(Method "#{method}" not yet implemented)
			result = "**N/A**"
		rescue StandardError => ex
			puts "Unexpected error: #{ex.message}"
			result = "**ERROR**"
		ensure
			puts result + "\n\n" if !result.nil?
			out.puts file_out_array.join("\t") if !out.nil? && !file_out_array.nil?
		end	
	end
	
	def run_using_file(filename)
		puts "Let's go go go go go!\n\n"
		File.open("output.csv", "w") do |out|
		
			headers = [
				"Test Date",
				"Keyword",
				"A Number",
				"B Number",
				"Time Sent",
				"Time Received",
				"Beginning Balance",
				"Ending Balance",
				"Amount Charged",
				"Expected Result",
				"Actual Result",
				"P/F",
				"Remarks"
			]
			
			out.puts headers.join("\t")
		
			File.open(filename, "r") do |f|
				f.each_line { |line| execute_line(line, out)}
			end
		end
		
		self.html
	end
	
	def html
	end
	
	#Run the testkit using the web frontend via SQS
	def run_using_sqs
		import('com.amazonaws.services.sqs.AmazonSQSClient')
		queue_url = "https://sqs.ap-southeast-1.amazonaws.com/119554206391/lost_treasure"

		sqs = AmazonSQSClient.new
		loop do
			#puts "Waiting for messages..."
			messages = sqs.receive_message(queue_url).get_messages
		
			messages.each do |message|
				receipt_handle = message.get_receipt_handle
				message_body = JSON.parse(message.get_body, {symbolize_names: true})
				puts "#{message_body[:batch]} - #{message_body[:order_id]} : #{message_body[:data]}"
				sqs.delete_message(queue_url, receipt_handle)
			end
			sleep 0.25
		end
		
		puts "\nrun_using_sqs"		
	end
	
	
	

	
end