require 'java'
require 'RXTXComm.jar'

class Gsm_Modem

	def initialize(comm_port)
		import('gnu.io.CommPortIdentifier')
		import('gnu.io.SerialPort')
		@port_id = CommPortIdentifier.get_port_identifier comm_port
		@port = @port_id.open 'JRuby', 500
		@in = @port.input_stream
		@in_io = @in.to_io
		@out = @port.output_stream		
	end
	
	def execute(at_command)
		@out.write "#{at_command}\r\n".to_java_bytes
		while @in.available == 0
			#Wait until device responds
		end
		@in_io.read(@in.available)
		
	end
	

	def close
		@out.close if !@out.nil?
		@in.close if !@in.nil?
		@port.close if !@port.nil?
	end

	
end