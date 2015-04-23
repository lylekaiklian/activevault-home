require 'dongle'
require 'siemens_mc39i_dongle'
require 'huawei_dongle'

# The Factory Method pattern is used for putting a layer of abstraction on top of object creation so 
# that directly working with its constructor is no longer necessary. 
# This process can lead to more expressive ways of building new objects, and can also allow for the 
# creation of new objects without explicitly referencing their class.
# http://blog.rubybestpractices.com/posts/gregory/059-issue-25-creational-design-patterns.html

# Usage:
# Instead of
# dongle = HuaweiDongle.new('COM4')
# We do
# dongle = DongleFactory.dongle(:huawei, 'COM4')


class DongleFactory
  def self.dongle(dongle_type, port)
    case dongle_type
    when :huawei
      HuaweiDongle.new(port)
    when :siemens_mc39i
      SiemensMc39iDongle.new(port)
    when :default
      SiemensMc39iDongle.new(port)
    end
  end
end