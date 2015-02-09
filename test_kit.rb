require 'dongle'

##
# Here lies the promo codes we humans are all familiar with!
##
class TestKit
	def initialize(comm_port)
		
		#Put this into config file later
		@sticks = {
			"A" => {
					"port" => "COM4", 
					"number" => "+639154322739",
					"dongle_object" => Dongle.new "COM4",
					"balance" => nil
					},
			"B" =>	{
					"port" => "COM5", 
					"number" => "+639173292739",
					"dongle_object" => Dongle.new "COM5",
					"balance" => nil
					}
		}
	end

	def send_and_must_receive(number, sms_content, response_regex)
		test_result = nil
		@dongle.send_message(number, sms_content)		
		@dongle.wait_for_new_message do |response|
			message = response[:message]
			test_result = ((response_regex =~ response) === true)
		end
		
		return test_result
	end
	
	def is_charged(amount, &block)
	end

	def close
		@sticks["A"]["dongle_object"].close if !@sticks["A"]["dongle_object"].nil?
		@sticks["B"]["dongle_object"].close if !@sticks["B"]["dongle_object"].nil?
	end	
	
	def run
		puts "Let's go go go go go!"
	end
	
end