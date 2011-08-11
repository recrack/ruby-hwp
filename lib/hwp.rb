# coding: utf-8
# 한글과컴퓨터의 글 문서 파일(.hwp) 공개 문서를 참고하여 개발하였습니다.

require 'hwp/version.rb'
require 'hwp/document.rb'

module HWP
    def self.open filename
        Document.new filename
    end
end
