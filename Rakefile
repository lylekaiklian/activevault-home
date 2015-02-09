task :default do
	puts "Project Lost Treasure"
end

namespace :dev do
	task :dongle do
		require 'dongle'
		require 'thread'
		dongle = Dongle.new "COM4"
		begin
		dongle.model
		dongle.manufacturer		
		dongle.messages
		dongle.send_message "222", "BAL"
		sleep 60
		puts "Check for new message"
		dongle.messages

		
		b = Queue.new
		b.pop
		
		ensure
			dongle.close if !dongle.nil?
		end
	end
	
	task :gsm_modem do
		require 'gsm_modem'
		begin
			gsm_modem = Gsm_Modem.new "COM4"
			gsm_modem.execute %Q(AT+CMGF=1)   
			gsm_modem.execute %Q(AT+CMGL="ALL")
		ensure
			gsm_modem.close if !gsm_modem.nil?
		end
	end
end