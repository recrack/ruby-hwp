# coding: utf-8
# apt-get install libole-ruby or gem install ruby-ole

require './hwp.rb'

if __FILE__ == $PROGRAM_NAME
	if ARGV.length == 0
		puts "Usage: $ ruby hwp.rb filename.hwp"
		exit
	end

	hwp = HWP::Reader.new(ARGV[0])
	hwp.body_text.parse
end
