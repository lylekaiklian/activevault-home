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
				
		
	end
	
	def execute(at_command, &block)
		@out.write "#{at_command}\r\n".to_java_bytes
		return_input = ""
		
		#Consume all input from the device
		loop do
			input = @response_queue.pop
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
			input = @response_queue.pop
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

	
end