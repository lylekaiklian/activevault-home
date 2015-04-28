#require 'spec_helper'

describe 'Siemens MC39i' do
  
  before :all do
    require 'yaml'
    require 'dongle_factory' 
    @sticks = YAML::load(File.read('ports.yml'))
  end
  
  before :each do     
  end
  
  describe 'USSD' do
    
      
    it 'must have a main menu' do      
      port = @sticks[:A][:port]
      
      DongleFactory.dongle(:siemens_mc39i, port) do |dongle|
        result = dongle.ussd(number: "*143#")
        expect(result).to_not be_nil
        expect(result.length).to be > 0
        expect(result).to match(/^1 GoSAKTO/)
      end      
    end
    
    it 'must have a submenu' do
      port = @sticks[:A][:port]      
      DongleFactory.dongle(:siemens_mc39i, port)  do |dongle|
        result = dongle.ussd(number: "*143#", commands:[1])
        expect(result).to_not be_nil
        expect(result.length).to be > 0
        expect(result).to match(/^1 Create a promo/)
      end       
    end
    
    it 'must be able to span multiple submenus' do
      port = @sticks[:A][:port]      
      DongleFactory.dongle(:siemens_mc39i, port)  do |dongle|
        result = dongle.ussd(number: "*143#", commands:[1, 7])
        expect(result).to_not be_nil
        expect(result.length).to be > 0
        expect(result).to match(/^What type of CALLS do you want/)
      end             
    end
   
  end
end