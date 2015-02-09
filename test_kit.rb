require 'dongle'

##
# Here lies the promo codes we humans are all familiar with!
##
class TestKit
	def initialize(comm_port)
		@dongle = Dongle.new comm_port
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
		@dongle.close if !@dongle.nil?
	end	
	
end