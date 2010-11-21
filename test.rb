#!/usr/bin/ruby1.9.1
# coding: utf-8
$LOAD_PATH << '/home/cogniti/ruby-hwp/lib'

require 'hwp'
hwp = HWP.open ARGV[0]

# hwp.header.gzipped?
# hwp.doc_info
# hwp.doc_info.char_shapes.length
# hwp.doc_info.char_shapes.each { |shape| p shape }
# hwp.doc_info.document_properties
# hwp.doc_info.id_mappings
# p hwp.doc_info.bin_data
# p hwp.doc_info.bin_data[0].type
# p hwp.doc_info.bin_data[0].id
# p hwp.doc_info.bin_data[0].format
# p hwp.doc_info.bin_data[0].compress_policy
# p hwp.doc_info.bin_data[0].status
# p hwp.doc_info.face_names
# p hwp.doc_info.face_names[0].font_type_info
# p hwp.doc_info.face_names[0].font_type_info.family

#p hwp.bodytext
#p hwp.bodytext.sections
parser = HWP::Parser.new hwp.bodytext.sections[0]
while parser.has_next?
	response = parser.pull
	case response.class.to_s
	when "Record::Section::ParaText"
	end
end
