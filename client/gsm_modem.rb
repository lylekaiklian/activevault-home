require 'java'
require 'RXTXComm.jar'
require 'thread'
require 'queue_with_timeout'
require 'lost_treasure_exceptions/gsm_cms_error'
require 'lost_treasure_exceptions/gsm_timeout_exceeded_exception'

##
# Here is the abstraction of a GSM Modem, how to get input into it,
# and how to get output from it.
# The responsibility of the Gsm_Modem starts from the issue of the AT Command or an asynchronous signal,
# and ends when the modem finally replies either OK or +CMS ERROR
##
class Gsm_Modem

	attr_accessor :timeout_seconds
	attr_accessor :debug

	def initialize(comm_port)
		import('gnu.io.CommPortIdentifier')
		import('gnu.io.SerialPort')
		@port_id = CommPortIdentifier.get_port_identifier comm_port
		@port = @port_id.open 'JRuby', 500
		
		@port.setSerialPortParams(
		  115200,   #baud rate
		  SerialPort::DATABITS_8,   #data bits
		  SerialPort::STOPBITS_1,#stop bits
		  SerialPort::PARITY_NONE#parity bits
		)
		
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
		
	
	def execute(at_command, at_command_2 = nil, &block)
		
		@out.write "#{at_command}\r\n".to_java_bytes
		#@out.write "#{at_command}#{suffix}"
		puts "gsm_modem.execute: query:  #{at_command}"
		
		if !at_command_2.nil?
		  puts "gsm_modem.execute: query 2: #{at_command_2}"
		  sleep 0.1 #Wait for prompt
		  @out.write "#{at_command_2}\r\n".to_java_bytes
		end
		
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
				raise LostTreasureExceptions::GsmTimeoutExceededException.new("Exceeded timeout of #{@timeout_seconds} seconds") if final - start > @timeout_seconds
				sleep timeout_throttle #Throttle loop				
			end
			
			return_input += input
			
			if input =~ /OK\r\n/
				break				
			elsif input =~/\+CMS ERROR/
			  raise LostTreasureExceptions::GsmCmsError.new(input)
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
=begin
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
=end
	
	#Open the input queue for a certain number of seconds,
	#and process listeners.
	# Wait for loops until the following happens, whichever goes first:
	# * The waiting_timeout expires, or
	# * The waiting_counter maxes out. The waiting counter can be incremented by 
	#   functions in the lambda_array
	# The lambda_array is an array of function transformations for the incoming message, of the
	# form:
	# new_input, waiting_timeout_incremement = function(old_input)  
	def wait_for(waiting_timeout, waiting_counter,  lambda_array)
		start_time = Time.now
		timeout_throttle = 0.3
		return_value = []
		current_waiting_counter = 0
		loop do
			final_time = Time.now
			begin
				input = @response_queue.pop(true)
			rescue StandardError => ex
				#carry on
			end	
			
			if !input.nil? 
			  puts "gsm_modem.wait_for: input #{input}"
				lambda_array.each do |l|
				    if !input.nil?
				      #do the lambda transformation, for each lambda
					   input, increment = l.call(input)
					   if !increment.nil?
					     current_waiting_counter = current_waiting_counter + increment 
					     puts "gsm_modem.wait_for: SMS increment #{increment}"
					     puts "gsm_modem.wait_for: SMS #{current_waiting_counter} / #{waiting_counter}"
					   end
					end
				end
				
			  #filter out unwanted input
			  next if input.nil?
				
				puts "gsm_modem.wait_for: input after lambda: #{input}"
				
				# After input has been properly mangled, prepare as return value.
        return_value << input
			end
			

			
			#Do not wait forever.
			# Exit either on a specific timeout, or if we got all that we need,
			# Whichever came first.
			
			break if (final_time - start_time > waiting_timeout) || current_waiting_counter >=  waiting_counter
			
			raise LostTreasureExceptions::GsmTimeoutExceededException.new("Exceeded timeout of #{waiting_timeout} seconds") if final_time - start_time > waiting_timeout && return_value.count == 0
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