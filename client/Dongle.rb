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
			matches = /IMEI:[\s]*(.*)[\s]*/.match(response)
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
				return "#{block.call(response)}"
			else
				return response
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
		response = @gsm_modem.execute "AT+CMGF=1" do |response|
			response += @gsm_modem.execute %Q(AT+CMGS="#{number}"\r\n#{message}\x1a)
		end
		
		response
	end
	
	def messages
		@gsm_modem.execute %Q(AT+CMGL="ALL")
	end
	
	def delete_message(index, &block)
		puts "deleting message #{index}"
		@gsm_modem.execute %Q(AT+CMGD=#{index}) do |response|
			#Allow further chaining
			if !block.nil?
				response += "#{block.call(response)}"
			end
			response
		end
	end
	
	def delete_all_messages(start_index = 0, &block)
		#Assume sim card has 30 messages.
		#Bad assumption, but may just work for now.
		upper_limit = 30 
		
		if start_index >= upper_limit
			if !block.nil?
				return block.call
			else
				return
			end
		end
		
		delete_message(start_index) do
			delete_all_messages(start_index + 1)
		end
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
	
	def self.port_sweep(timeout_seconds = nil)
		sticks = {}
		labels = ('A'..'Z').to_a
		import('gnu.io.CommPortIdentifier')
		CommPortIdentifier.getPortIdentifiers.each do |port_ids|
			port = port_ids.get_name
			puts "Sweeping port #{port}..."
			dongle = nil
			begin
				dongle = Dongle.new(port)
				dongle.gsm_modem.timeout_seconds = timeout_seconds if !timeout_seconds.nil?
				puts(dongle.imei do |response1|
					number = (dongle.number do |response2|
						"Number: #{response2}\n"
					end)
					"IMEI: #{response1}\n#{number}"
				end)
			rescue ThreadError => ex
				puts ex.message
				next
			rescue NoMethodError =>ex2
				puts "Number not yet set"
				next
			rescue Java::GnuIo::PortInUseException => ex
				puts "Port #{port} in use." 
				next
			rescue StandardError => ex3
				puts "Uncaught exception #{ex3.class.name} please fix"
				raise ex3
			ensure
				dongle.close if !dongle.nil?
			end

		end
		puts "Done!"
	end	

end