require 'gsm_modem'

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
	
	def close
		@gsm_modem.close if !@gsm_modem.nil?
	end
	
	#cleans the output of GSM geekiness
	def scrub(text)
		text = text.gsub(/(\r\nOK\r\n)$/, '')
		text = text.gsub(/[\r\n]/, '')
		text = text.chomp
	end

end