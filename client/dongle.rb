require 'gsm_modem'
require 'json'
require 'lost_treasure_exceptions/gsm_timeout_exceeded_exception'
require 'lost_treasure_exceptions/sms_sending_failed_exception'

##
# The magical AT Commands lie on subclasses of Dongle.
# Each "dongle" device has their own set of AT Commands, and we should
# adjust accordingly.
##
class Dongle

	attr_reader :gsm_modem

	def initialize(comm_port, &block)
		@gsm_modem = Gsm_Modem.new comm_port
		
		if !block.nil?
		  begin
		    block.call(self)
		  ensure
		    close
		  end
		end
		
	end
	
	def close
		@gsm_modem.close if !@gsm_modem.nil?
	end
	
	#cleans the output of GSM geekiness
	def scrub(text)
		text.gsub(/(\r\nOK\r\n)$/, '').strip
	end
	
	def self.port_sweep(mode = :simple)
		sticks = {}
		labels = ('A'..'Z').to_a
		label_index = 0
		seen_imei = []	#collect all imei's encountered already so as not to repeat.
		import('gnu.io.CommPortIdentifier')

    # Available modes:
    # :simple - just see ports available in the system. Very fast.
    # :info - issue an "ATI" command to all ports. For simple port check.
    # :identity - obtain IMEI and number for all ports. 
    # :complete - issues balance inquiry as well. Takes a bit of time.
    				
		CommPortIdentifier.getPortIdentifiers.each do |port_ids|
			port = port_ids.get_name
			puts "\nSweeping port #{port}..."
			dongle = nil
			imei = nil
			number = nil
			balance = nil
			begin
				dongle = Dongle.new(port)

				case mode
				when :simple
				  dongle.gsm_modem.timeout_seconds = 10
				  puts "Port #{port} is operational."
				when :info
				  dongle.gsm_modem.timeout_seconds = 10
				  puts dongle.device_info
				when :identity
				  dongle.gsm_modem.timeout_seconds = 10
          dongle.imei do |response1|
               imei = response1.strip
               dongle.number do |response2|
                 number = response2.strip
               end         
              end
              puts "IMEI: #{imei}"
              puts "Number: #{number}"				  
				when :complete
				  dongle.gsm_modem.timeout_seconds = 30
          dongle.imei do |response1|
             imei = response1.strip
             dongle.number do |response2|
               number = response2.strip
               balance = dongle.balance_inquiry 
             end         
            end
            puts "IMEI: #{imei}"
            puts "Number: #{number}"
            puts "Balance: #{balance[:balance]}"				  
				end
				

				
				# If this is a new IMEI, then record it.
				# Disregard ports that cannot do balance inquiry
				#if !seen_imei.member? imei #&& !(must_have_balance && balance.nil?)
				
					label = labels[label_index].to_sym
					sticks[label] = {
						port: port,
						number: number,
						imei: imei,
						dongle_object:  nil,
						description: nil, 
						balance: nil,
						reply_number: nil
					}
					
					#raise "Please assign number first to device #{imei}." if imei.empty?
					
					seen_imei << imei
					label_index += 1
				
				
			rescue LostTreasureExceptions::GsmTimeoutExceededException => ex
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
		sticks
	end	

end
