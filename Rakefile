task :default do
	puts "Project Lost Treasure"
end

task :dev do
	require 'dongle'
	dongle = Dongle.new "COM4"
	puts dongle.manufacturer + " " + dongle.model
	dongle.close
end