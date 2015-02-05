task :default do
	puts "Project Lost Treasure"
end

namespace :dev do
	task :dongle do
		require 'dongle'
		dongle = Dongle.new "COM4"
		begin
		#dongle.flush
		#puts dongle.model
		#sleep 45
		#puts "Checking load..."
		#puts dongle.send_message "222", "BAL"
		#sleep 45
		#puts "Press enter to proceed"
		#gets
		puts dongle.messages
		ensure
			dongle.close if !dongle.nil?
		end
	end
	
	task :gsm_modem do
		require 'gsm_modem'
		gsm_modem = Gsm_Modem.new "COM4"
		gsm_modem.execute %Q(AT+CMGF=1)   
		puts gsm_modem.execute %Q(AT+CMGL="ALL")
		gsm_modem.close
	end
end