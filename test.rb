#!/usr/bin/ruby1.9.1
# coding: utf-8
# 한글과컴퓨터의 글 문서 파일(.hwp) 공개 문서를 참고하여 개발하였습니다.
# $LOAD_PATH 를 자신의 적절한 디렉토리로 바꾸어 주세요.
$LOAD_PATH << '/home/cogniti/ruby-hwp/lib'

require 'hwp'
hwp = HWP.open ARGV[0]

# hwp.header.compress?
# hwp.doc_info
# hwp.doc_info.char_shapes.length
# hwp.doc_info.char_shapes.each { |shape| p shape }
#p hwp.doc_info.char_shapes[0].lang[:korean].font_id
#p hwp.doc_info.char_shapes[0].lang[:korean].ratio
#p hwp.doc_info.char_shapes[0].lang[:korean].char_spacing
#p hwp.doc_info.char_shapes[0].lang[:korean].rel_size
#p hwp.doc_info.char_shapes[0].lang[:korean].char_offset

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
#p hwp.bodytext.para_headers
