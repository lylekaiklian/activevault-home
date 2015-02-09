task :default do
	puts "Project Lost Treasure"
end

namespace :dev do
	task :dongle do
		require 'dongle'
		require 'thread'
		require 'json'
		
		dongle = Dongle.new "COM4"
		begin
		#dongle.model
		#dongle.manufacturer		
		#dongle.messages
		#dongle.send_message "222", "BAL"
		#sleep 60
		#puts "Check for new message"
		#dongle.messages
		puts dongle.number

		
		#b = Queue.new
		#b.pop
		
		ensure
			dongle.close if !dongle.nil?
		end
	end
	
	task :gsm_modem do
		require 'gsm_modem'
		begin
			gsm_modem = Gsm_Modem.new "COM4"
			#puts gsm_modem.execute %Q(AT+CMGF=1)   
			#puts gsm_modem.execute %Q(AT+CMGL="ALL")
			#puts gsm_modem.execute %Q(AT+CGMI)
			#puts gsm_modem.execute %Q(AT+CGMM)
			#puts gsm_modem.execute %Q(AT+CMGS="222"\r\nBAL\x1a)
			#gsm_modem.execute %Q(AT+CMGL="ALL")	do |response|
			#	puts response.upcase
			#end
			
			puts gsm_modem.execute "AT+CNUM"
			puts gsm_modem.execute %Q(AT+CMGS="222"\r\nBAL\x1a)
			gsm_modem.wait_for(/^\+CMTI/) do |response|
				matches = /^\+CMTI: "[^"]*",(\d+)/.match(response)
				message_index = matches[1]
				puts gsm_modem.execute %Q(AT+CMGR=#{message_index})
			end
		ensure
			gsm_modem.close if !gsm_modem.nil?
		end
	end
	
	task :test_kit do
		require 'test_kit'
		test_kit = TestKit.new "COM4"
		begin
			#puts test_kit.balance_inquiry
		ensure		
			test_kit.close if !test_kit.nil?
		end
	end
end

namespace :util do
	task :send, :number, :message do |task, args|
		require 'dongle'
		begin
			dongle = Dongle.new "COM4"
			dongle.send_message(args[:number], args[:message])
		ensure
			dongle.close if !dongle.nil?
		end
	end
	
	task :send_and_expect, :number, :message do |task, args|
		require 'dongle'
		begin
			dongle = Dongle.new "COM4"
			dongle.send_message(args[:number], args[:message])
			puts dongle.wait_for_new_message
		ensure
			dongle.close if !dongle.nil?
		end	
	end
	
	task :bal do 
		require 'dongle'
		begin
			dongle = Dongle.new "COM4"
			puts dongle.balance_inquiry
		ensure
			dongle.close if !dongle.nil?
		end	
	end
	
	task :num do
		require 'dongle'
		begin
			dongle = Dongle.new "COM4"
			puts dongle.number
		ensure
			dongle.close if !dongle.nil?
		end		
	end
end

namespace :test do
	task :case1 do
		puts "Case 1"
	end

end