require 'java'
require 'RXTXComm.jar'
require 'thread'
require 'queue_with_timeout'
##
# Here is the abstraction of a GSM Modem, how to get input into it,
# and how to get output from it.
##
class Gsm_Modem

	attr_accessor :timeout_seconds
	attr_accessor :debug

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
		@timeout_seconds = 10
		@debug = false
		
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
		#puts "Execute #{at_command}"
		@out.write "#{at_command}\r\n".to_java_bytes
		puts "gsm_modem.execute: query:  #{at_command}"
		return_input = ""
		
		#Consume all input from the device
		loop do
			#input = @response_queue.pop_with_timeout(@timeout_seconds)

			#resort to polling and non-blocking pop to have a timeout
			start = Time.now
			input = ""
			
			#Insist until we have input
			timeout_throttle = 0.3
			loop do
				final = Time.now
				begin				
					input = @response_queue.pop(true)
				rescue StandardError => ex
					#carry on
				end
				
				puts "gsm_modem.execute: response:  #{input}"
				#puts input if @debug
				#puts "#{final - start}"
				break if !input.empty?
				raise ThreadError, "Exceeded timeout of #{@timeout_seconds} seconds" if final - start > @timeout_seconds
				sleep timeout_throttle #Throttle loop				
			end
			
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
			start = Time.now
			input = ""
			timeout_throttle = 0.3
			loop do
				final = Time.now
				begin
					input = @response_queue.pop(true)
				rescue StandardError => ex
					#carry on
				end	
				
				break if !input.empty?
				raise ThreadError, "Exceeded timeout of #{@timeout_seconds} seconds" if final - start > @timeout_seconds
				sleep timeout_throttle #Throttle loop	
			end
			
			if input =~ interrupt_regex
				block.call input
			end			
		end
	end
	
	#Open the input queue for a certain number of seconds,
	#and process listeners
	def wait_for_via_listeners(waiting_timeout, lambda_array)
		start_time = Time.now
		timeout_throttle = 0.3
		return_value = []
		loop do
			final_time = Time.now
			begin
				input = @response_queue.pop(true)
			rescue StandardError => ex
				#carry on
			end	
			
			if !input.nil?
				lambda_array.each do |l|
					lambda_result = l.call(input)
					return_value << "#{lambda_result}" if !lambda_result.nil?
				end
			end
			
			break if final_time - start_time > waiting_timeout && return_value.count > 0
			raise ThreadError, "Exceeded timeout of #{waiting_timeout} seconds" if final_time - start_time > waiting_timeout && return_value.count == 0
			sleep timeout_throttle #Throttle loop	
		end	
		return_value
	end
	

	def close
		@producer.kill
		
		@out.close if !@out.nil?
		@in.close if !@in.nil?
		@port.close if !@port.nil?		
	end
	


	class Timeout < StandardError
	end
	
end