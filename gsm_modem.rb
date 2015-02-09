require 'java'
require 'RXTXComm.jar'
require 'thread'

class Gsm_Modem

	def initialize(comm_port)
		import('gnu.io.CommPortIdentifier')
		import('gnu.io.SerialPort')
		@port_id = CommPortIdentifier.get_port_identifier comm_port
		@port = @port_id.open 'JRuby', 500
		@in = @port.input_stream
		@in_io = @in.to_io
		@out = @port.output_stream	
		@response_queue = Queue.new
		@callback_queue = Queue.new
		@command_queue = Queue.new
		
		#The purpose of this thread is to convert the asynchronous incoming stream
		#of the device into a neat queue of strings.
		@producer = Thread.new do
			incoming_message = ""
			loop do
				in_available = @in.available
				if in_available > 0
					incoming_message += @in_io.read(1)
					if incoming_message[-2..-1] == "\r\n"
						@response_queue.push(incoming_message)
						incoming_message = ""
					end
					
				end
			end
		end
		
		@consumer = Thread.new do
			loop do
				input = @response_queue.pop
				puts "#{input}"
				if input =~ /OK\r\n/ || input =~/\+CMS ERROR/
					#puts "Ready to receive more commands!"
					Thread.main.wakeup
				end
			end
		end
		
		
	end
	
	def execute(at_command, regex_listener=nil, callback=nil)
		@out.write "#{at_command}\r\n".to_java_bytes
		sleep
	end
	
	def flush
		while @in.available == 0
			#Wait until device responds
		end
		@in_io.read(@in.available)
	end

	def wait
		loop do
		end
	end

	def close
		@out.close if !@out.nil?
		@in.close if !@in.nil?
		@port.close if !@port.nil?
	end

	
end