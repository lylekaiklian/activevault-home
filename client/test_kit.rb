require 'dongle'
require 'java'
require 'jar/aws-java-sdk-1.9.20.1.jar'
require 'jar/commons-logging-1.2.jar'
require 'jar/jackson-databind-2.3.1.jar'
require 'jar/jackson-core-2.5.0.jar'
require 'jar/jackson-annotations-2.5.0.jar'
require 'jar/httpcore-4.4.jar'
require 'jar/httpclient-4.4.jar'

##
# Here lies the promo codes we humans are all familiar with!
##
class TestKit

	attr_accessor :timeout_seconds

	def initialize(params={})
	
		@timeout_seconds = params[:timeout_seconds] || 60
		
		#Put this into config file later, 
		#and let the kit query the dongles future releases
=begin		
		@sticks = {
		
			:A => {
					port: "COM4", 
					number: "+639054292739",
					dongle_object:  Dongle.new("COM4"),
					description: "yellow dongle", 
					balance: nil,
					reply_number: nil
			},	

		:B =>	{
					port: "COM9", 
					number: "+639062627862",
					dongle_object: Dongle.new("COM9"),
					description: "blue dongle",
					balance: nil,
					
					reply_number: nil
					}
		}
=end
		@sticks = Dongle.port_sweep(5)
		
		puts "Sanity check"
		@sticks.keys.each do |key|
			@sticks[key][:dongle_object] = Dongle.new(@sticks[key][:port])
			@sticks[key][:dongle_object].gsm_modem.timeout_seconds = @timeout_seconds
			puts "Information for #{key}:"
			puts @sticks[key]
		end
	end

	def send_and_must_receive(parameters)
		stick = parameters[0]
		number = parameters[1]
		message = parameters[2]
		regex = parameters[3]
		
		#deal with 29173292739
		if matches = number.match(/2\+([A-Z])/)			
			original_number = @sticks[matches[1].to_sym][:number]
			number = "2" + original_number[-10, original_number.length - 1]
		end
		
		dongle = @sticks[stick.to_sym][:dongle_object]
		dongle.send_message(number, message)
		response = dongle.wait_for_new_message(60)
		
		@sticks[stick.to_sym][:reply_number] = response[:sender]
		response_message = response[:message]
		puts response_message
		
		# Tame Regex later
		#return (/#{regex}/ =~ response_message)
		#puts /#{regex}/
		puts "Match?" + ((/#{regex}/ =~ response_message) ? "true" : "false")
		if !(/#{regex}/ =~ response_message).nil?
			return true
		else
			return [false, "Pattern does not match"]
		end
			
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
			puts "COMMENT: #{line}"
			result = "**N/A**"
			puts result + "\n\n"
			return
		end
		
	
		commands = line.split(",")
		method = commands[1].strip
		parameters = Array.new(commands).map{|p| p.strip}
		
		parameters.delete_at(1)
		puts "[#{method}(#{parameters.join(",")})]"
		begin
			#puts self.class.name
			truth, reason = self.send(method, parameters)
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
		
		ensure
			puts result + "\n\n"
			out.puts result + "," + line.strip if !out.nil?
		end	
	end
	
	def run_using_file(filename)
		puts "Let's go go go go go!\n\n"
		File.open("output.csv", "w") do |out|
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