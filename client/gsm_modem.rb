require 'java'
require 'RXTXComm.jar'
require 'thread'
require 'queue_with_timeout'
##
# Here is the abstraction of a GSM Modem, how to get input into it,
# and how to get output from it.
##
class Gsm_Modem

	def initialize(comm_port)
		import('gnu.io.CommPortIdentifier')
		import('gnu.io.SerialPort')
		@port_id = CommPortIdentifier.get_port_identifier comm_port
		@port = @port_id.open 'JRuby', 500
		@in = @port.input_stream
		@in_io = @in.to_io
		@out = @port.output_stream	
		@response_queue = QueueWithTimeout.new
		@callback_queue = Queue.new
		@command_queue = Queue.new
		@timeout_seconds = 10
		
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
				
		
	end
	
	def execute(at_command, &block)
		@out.write "#{at_command}\r\n".to_java_bytes
		return_input = ""
		
		#Consume all input from the device
		loop do
			input = @response_queue.pop_with_timeout(@timeout_seconds)
			return_input += input
			
			if input =~ /OK\r\n/ || input =~/\+CMS ERROR/
				break
			end
		end
		
		if !block.nil?
			return block.call return_input 
		else
			return return_input
		end
	end
	

	#Wait for an AT "Interrupt", while ignoring/dropping others that
	#do not qualify
	def wait_for(interrupt_regex, &block)
		loop do
			input = @response_queue.pop_with_timeout(@timeout_seconds)
			if input =~ interrupt_regex
				return block.call input
			end
		end
	end

	def close
		@out.close if !@out.nil?
		@in.close if !@in.nil?
		@port.close if !@port.nil?
	end
	
	def self.port_sweep
		require 'dongle'
		import('gnu.io.CommPortIdentifier')
		CommPortIdentifier.getPortIdentifiers.each do |port_ids|
			port = port_ids.get_name
			puts "Sweeping port #{port}..."
			x = nil
			begin
				x = Dongle.new(port)
				puts x.number
			rescue ThreadError => ex
				next
			rescue NoMethodError =>ex2
				puts "Number not yet set"
				next
			ensure
				x.close if !x.nil?
			end
		end
	end

	class Timeout < StandardError
	end
	
end