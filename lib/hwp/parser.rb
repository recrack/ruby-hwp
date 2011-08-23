# coding: utf-8
# 한글과컴퓨터의 글 문서 파일(.hwp) 공개 문서를 참고하여 개발하였습니다.

require 'hwp/tags.rb'

module HWP
    class Context
        attr_reader   :tag_id, :level, :data
        attr_accessor :stack

        def initialize stream
            @stream = stream
            @stack = []
        end

        def has_next?
            not @stream.eof?
        end

        def record_header_decode
            # 이진수, LSB first, bit 0 가 맨 앞에 온다.
            lsb_first = (@stream.read 4).unpack("b*")[0]

            if lsb_first
                k = lsb_first[0..9].reverse.to_i(2)   # 9~0
                #p k
                @tag_id = HWPTAGS[k]
                @level  = lsb_first[10..19].reverse.to_i(2) # 19~10
                size    = lsb_first[20..31].reverse.to_i(2) # 31~20
            else
                raise
            end
            @data = @stream.read size

            puts " " * @level + @tag_id.to_s
        end

        def pull
            record_header_decode
        end
    end # Context
end
