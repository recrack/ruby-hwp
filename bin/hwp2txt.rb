# coding: utf-8
# apt-get install libole-ruby or gem install ruby-ole

require '~/libhwp/hwp.rb'
require '~/libhwp/parser.rb'

if __FILE__ == $PROGRAM_NAME
	if ARGV.length == 0
		puts "Usage: $ ruby hwp.rb filename.hwp"
		exit
	end

	hwp = HWP::Reader.new(ARGV[0])
	hwp.bodytext.sections.each do |section|
		parser = HWP::Parser.new section
		while parser.has_next?
			response = parser.pull
			case response.class.to_s
			when "Record::Data::ParaText"
				puts response.to_s
			when "Record::Data::EQEdit"
				puts response.to_s
			else
			end
		end
	end
	hwp.close
end
