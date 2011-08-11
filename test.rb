#!/usr/bin/ruby1.9.1
# coding: utf-8
# 한글과컴퓨터의 글 문서 파일(.hwp) 공개 문서를 참고하여
# 개발하였습니다.

begin
    require 'hwp'
rescue Exception
    $LOAD_PATH << File.expand_path(File.dirname(__FILE__)) + '/lib'
    require 'hwp'
end

require 'test/unit'

class TestHWP < Test::Unit::TestCase
    def setup
        if ARGV[0]
            @doc = HWP.open ARGV[0]
        else
            @doc = HWP.open(File.expand_path(File.dirname(__FILE__)) +
                "/samples/kreg1.hwp")
        end
    end

    def test_FileHeader
        #assert(@doc.header, "header")
        #assert(@doc.header.signature, "signature")
        #assert(@doc.header.version, "version")
        assert([true, false].include?(@doc.header.compress?),
            "compress")
        assert([true, false].include?(@doc.header.encrypt?),
            "encrypt")
        assert([true, false].include?(@doc.header.distribute?),
            "distribute")
        assert([true, false].include?(@doc.header.script?),
            "script")
        assert([true, false].include?(@doc.header.drm?), "drm")
        assert([true, false].include?(@doc.header.xml_template?),
            "xml_template")
        assert([true, false].include?(@doc.header.history?), "history")
        assert([true, false].include?(@doc.header.sign?), "sign")
        assert([true, false].include?(@doc.header.certificate_encrypt?),
            "certificate_encrypt")
        assert([true, false].include?(@doc.header.sign_spare?),
            "sign_spare")
        assert([true, false].include?(@doc.header.certificate_drm?),
            "certificate_drm")
        assert([true, false].include?(@doc.header.ccl?), "ccl")
    end
end

# doc.doc_info
# doc.doc_info.char_shapes.length
# doc.doc_info.char_shapes.each { |shape| p shape }
#p @doc.doc_info.char_shapes[0].lang[:korean].font_id
#p @doc.doc_info.char_shapes[0].lang[:korean].ratio
#p @doc.doc_info.char_shapes[0].lang[:korean].char_spacing
#p @doc.doc_info.char_shapes[0].lang[:korean].rel_size
#p @doc.doc_info.char_shapes[0].lang[:korean].char_offset

# doc.doc_info.document_properties
# doc.doc_info.id_mappings
# p doc.doc_info.bin_data
# p doc.doc_info.bin_data[0].type
# p doc.doc_info.bin_data[0].id
# p doc.doc_info.bin_data[0].format
# p doc.doc_info.bin_data[0].compress_policy
# p doc.doc_info.bin_data[0].status
# p doc.doc_info.face_names
# p doc.doc_info.face_names[0].font_type_info
# p doc.doc_info.face_names[0].font_type_info.family

#p @doc.body_text
#p @doc.body_text.para_headers
