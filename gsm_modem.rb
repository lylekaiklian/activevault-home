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
		
		@producer = Thread.new do
			loop do
				in_available = @in.available
				if in_available > 0
					incoming_message = @in_io.read(in_available)
					#puts "PUSHING #{incoming_message} in queue"
					@response_queue.push(incoming_message)
				end
				#sleep 0.25
			end
		end
		
		@consumer = Thread.new do
			loop do
				input = @response_queue.pop
				puts "#{input}"
				if input =~ /OK\r\n/ || input =~/\+CMS ERROR/
					#puts "Ready to receive more commands!"
					@command_queue_consumer.wakeup
				end
			end
		end
		
		@command_queue_consumer = Thread.new do
			loop do
				command = @command_queue.pop
				puts "MESSAGE: #{command}"
				@out.write command
				#SLEEP until OK is received
				sleep
			end
		end
		
	end
	
	def execute(at_command, regex_listener=nil, callback=nil)
		@command_queue.push "#{at_command}\r\n".to_java_bytes
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