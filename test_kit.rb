require 'dongle'

##
# Here lies the promo codes we humans are all familiar with!
##
class TestKit
	def initialize(comm_port)
		@dongle = Dongle.new comm_port
	end



	def close
		@dongle.close if !@dongle.nil?
	end	
	
end