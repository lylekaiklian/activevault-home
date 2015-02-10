require 'dongle'

##
# Here lies the promo codes we humans are all familiar with!
##
class TestKit
	def initialize
		
		#Put this into config file later, 
		#and let the kit query the dongles future releases
		@sticks = {
			:A => {
					port: "COM4", 
					number: "+639154322739",
					dongle_object:  Dongle.new("COM4"),
					description: "yellow dongle", 
					balance: nil
					},
			:B =>	{
					port: "COM9", 
					number: "+639062627862",
					dongle_object: Dongle.new("COM9"),
					description: "blue dongle",
					balance: nil
					}
		}
		
		puts "Sanity check"
		@sticks.keys.each do |key|
			puts "Information for #{key}:"
			puts @sticks[key][:dongle_object].number
		end
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
		#Will clean. Sorry.
		@sticks[:A][:dongle_object].close if !@sticks[:A][:dongle_object].nil?
		@sticks[:B][:dongle_object].close if !@sticks[:B][:dongle_object].nil?
	end	
	
	def run
		puts "Let's go go go go go!"
	end
	
end