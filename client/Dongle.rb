require 'gsm_modem'
require 'json'
##
# Here lies the magical AT Commands
##
class Dongle

	attr_reader :gsm_modem

	def initialize(comm_port)
		@gsm_modem = Gsm_Modem.new comm_port
	end
	
	def device_info
		@gsm_modem.execute "ATI"
	end
	
	def manufacturer
		@gsm_modem.execute "AT+CGMI"
	end
	
	def number
		@gsm_modem.execute "AT+CNUM" do |response|
			matches = /\+CNUM: "[^"]*","([^"]*)",\d+/.match(response)
			return matches[1] 
		end
	end
	
	def model
		@gsm_modem.execute "AT+CGMM"
	end
		
	def send_message(number, message)
		@gsm_modem.execute "AT+CMGF=1"
		@gsm_modem.execute %Q(AT+CMGS="#{number}"\r\n#{message}\x1a)
	end
	
	def messages
		@gsm_modem.execute %Q(AT+CMGL="ALL")
	end
	
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
	
	def balance_inquiry
		send_message(222, "BAL")
		wait_for_new_message do |response|
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
		
		message_array.sort!{|x,y| y[:index] <=> x[:index]}.to_json
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