# coding: utf-8

require '~/libhwp/hwp.rb'
require '~/libhwp/parser.rb'
require 'builder'

if __FILE__ == $PROGRAM_NAME
	if ARGV.length == 0
		puts "Usage: $ ruby hwp.rb filename.hwp"
		exit
	end

	hwp = HWP::Reader.new(ARGV[0])

	parser = HWP::Parser.new hwp.doc_info
	while parser.has_next?
		response = parser.pull
	end

	builder = Builder::XmlMarkup.new(:target=>STDOUT, :indent=>2)
	builder.html do
		builder.head do
			builder.meta('http-equiv'=>'Content-Type', 'content'=>'application/html; charset=utf-8')
			builder.meta('name'=>'HWP File Format', 'version'=> hwp.header.version)
		end

		builder.body do
			hwp.bodytext.sections.each do |section|
				parser = HWP::Parser.new section
				while parser.has_next?
					response = parser.pull
					case response.class.to_s
					when "Record::Data::ParaText"
						parser.push response
					when "Record::Data::ParaCharShape"
						# FIXME m_pos 적용해야 한다.
						size = Record::Data::CharShape.char_shapes[response.m_id[0]].size[0]/100
						builder.div('style'=> "font-size: #{size}pt") do
							builder.p parser.pop.to_s
						end
					when "Record::Data::EQEdit"
						builder.p response.to_s
					else
					end
				end
			end
			hwp.close
		end
	end
end
