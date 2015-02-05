require 'RXTXComm.jar'
import('gnu.io.CommPortIdentifier')
import('gnu.io.SerialPort')
port_id = CommPortIdentifier.get_port_identifier "COM4"
@port = port_id.open 'JRuby', 500

    @in = @port.input_stream
    @in_io = @in.to_io
    @out = @port.output_stream
 