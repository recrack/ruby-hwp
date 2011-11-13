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
            l = (@stream.read 4).unpack("V")[0]

            if l
                @tag_id = HWPTAGS[l & 0x3ff]
                @level  = (l >> 10) & 0x3ff
                size    = (l >> 20) & 0x3ff
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
