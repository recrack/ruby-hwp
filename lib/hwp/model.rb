# coding: utf-8
# 한글과컴퓨터의 글 문서 파일(.hwp) 공개 문서를 참고하여 개발하였습니다.

module Record
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
end # Record

# HWP Document Model
module HWP
    module Model
        class Paragraph
        end
    end
end
