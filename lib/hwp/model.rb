# coding: utf-8
# 한글과컴퓨터의 글 문서 파일(.hwp) 공개 문서를 참고하여 개발하였습니다.

# TODO 루프 반복 줄이기
# .each, yield 를 parser.rb, model.rb 와 연관시키는 것을 고려한다.
# TODO BodyText, Modeller 를 알기 쉽게 개량해야 한다.

module Record
    module Header
        def self.decode bytes
            lsb_first = bytes.unpack("b*")[0] # 이진수, LSB first, bit 0 가 맨 앞에 온다.

            if lsb_first
                @tag_id	= lsb_first[0..9].reverse.to_i(2) # 9~0
                @level	= lsb_first[10..19].reverse.to_i(2) # 19~10
                @size	= lsb_first[20..31].reverse.to_i(2) # 31~20
            end
        end

        def self.tag_id;	@tag_id;	end
        def self.level;		@level;		end
        def self.size;		@size;		end
    end

    class ViewText
        def initialize dirent, header
            raise NotImplementedError.new("ViewText is not supported")
        end
    end

    class SummaryInformation; end

    class BinData
        def initialize(dirent, header);end
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

    class DocOptions;end
    class Scripts;end
    class XMLTemplate;end

    class DocHistory
        def initialize(dirent, header);end
    end
end # of (module Record)
