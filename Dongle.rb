require 'gsm_modem'
require 'json'

class Dongle

	def initialize(comm_port)
		@gsm_modem = Gsm_Modem.new comm_port
	end
	
	def manufacturer
		scrub @gsm_modem.execute "AT+CGMI"
	end
	
	def model
		scrub @gsm_modem.execute "AT+CGMM"
	end
	
	def send_message(number, message)
		@gsm_modem.execute "AT+CMGF=1"
		@gsm_modem.execute %Q(AT+CMGS="#{number}"\r\n)
		scrub @gsm_modem.execute %Q(#{message}\x1a)
	end
	
	def messages
		messages = @gsm_modem.execute %Q(AT+CMGL="ALL")
		messages = scrub messages
				
		#puts "#{messages.split("\r\n").count} messages"
		
		message_array = []
		message_array_item = {}
		messages.split("\r\n").each_with_index do |line, index|
			message_index = index / 2
			
			if index % 2 == 0 	# header
				
				x, header = line.split("CMGL:")
				message_index, status, carrier, x, smsdate, smstime = header.split(",")
				message_array_item = {
					index: message_index.to_i,
					status: status.sub(/^"(.*)"$/, '\1'),
					carrier: carrier.sub(/^"(.*)"$/, '\1'),
					smsdate: smsdate.sub(/^"(.*)/, '\1'),
					smstime: smstime.sub(/"(.*)$/, '\1')
				}
			else				# message body
				message_array_item[:message] = line
				message_array[message_index] = message_array_item
			end
		end
		
		message_array.to_json
		#messages
	end
	
	def close
		@gsm_modem.close if !@gsm_modem.nil?
	end
	
	#cleans the output of GSM geekiness
	def scrub(text)
		text.gsub(/(\r\nOK\r\n)$/, '').strip
	end

end