require 'java' 
require_relative 'RXTXcomm.jar'
 
import('gnu.io.CommPortIdentifier')
import('gnu.io.SerialPort') { 'GnuSerialPort' }

CommPortIdentifier.getPortIdentifiers.each {|port| puts port.getName}