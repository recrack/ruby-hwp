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
            l = (@stream.read 4).unpack("V")[0]
            @tag_id = HWPTAGS[l & 0x3ff]
            raise "unknown tag_id = #{l & 0x3ff}" if @tag_id.nil?
            @level  = (l >> 10) & 0x3ff
            size    = (l >> 20) & 0xfff

            @data = @stream.read size
            puts " " * @level + @tag_id.to_s
        end

        def pull
            record_header_decode
        end
    end # Context

    module Parser
        class BodyText
            attr_accessor :paragraphs

            def initialize(dirent, header)
                @paragraphs = []

                dirent.each_child do |section|
                    if header.compress?
                        z = Zlib::Inflate.new(-Zlib::MAX_WBITS)
                        context = HWP::Context.new StringIO.new(z.inflate section.read)
                        z.finish
                        z.close
                    else
                        context = HWP::Context.new StringIO.new(section.read)
                    end

                    parse(context)
                    #print_para_headers(self)
                end # dirent.each_child
            end # initialize

            # <BodyText> ::= <Section>+
            # <Section> ::= <ParaHeader>+
            # 여기서는 <BodyText> ::= <ParaHeader>+ 로 간주함.
            def parse(context)
                while context.has_next?
                    # stack 이 차 있으면 자식으로부터 제어를 넘겨받은 것이다.
                    context.stack.empty? ? context.pull : context.stack.pop

                    if context.tag_id == :HWPTAG_PARA_HEADER and context.level == 0
                        @paragraphs << Record::Section::ParaHeader.new(context)
                    else
                        # FIXME UNKNOWN_TAG 때문에...
                        @paragraphs << Record::Section::ParaHeader.new(context)
                        # FIXME 최상위 태그가 :HWPTAG_PARA_HEADER 가 아닐 수도 있다.
                        puts "최상위 태그가 HWPTAG_PARA_HEADER 이 아닌 것 같음"
                        # FIXME UNKNOWN_TAG 때문에.......
                        #raise "unhandled: #{context.tag_id}"
                    end
                end
            end

            def to_text
                # FIXME yield 로 속도 저하 줄일 것.
                text = ""
                @paragraphs.each do |para_header|
                    text << para_header.to_text + "\n"
                end
                text
            end
        end # BodyText

        class ViewText
            def initialize dirent, header
                raise NotImplementedError.new("ViewText is not supported")
            end
        end

        class SummaryInformation
            def initialize file
            end
        end

        class BinData
            def initialize(dirent, header)
            end
        end

        class PrvText
            def initialize(dirent)
                @dirent = dirent
            end

            def to_s
                @dirent.read.unpack("v*").pack("U*")
            end
        end

        class PrvImage
            def initialize(dirent)
                @dirent = dirent
            end

            def parse
                @dirent.read
            end
        end

        class DocOptions
            def initialize dirent
            end
        end

        class Scripts
            def initialize dirent
            end
        end

        class XMLTemplate
        end

        class DocHistory
            def initialize(dirent, header)
            end
        end
    end
end
