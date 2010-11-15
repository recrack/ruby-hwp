#!/usr/bin/ruby1.9.1
# coding: utf-8
$LOAD_PATH << '/home/cogniti/ruby-hwp/lib'

require 'hwp'
hwp = HWP.open 'samples/kreg1.hwp'

p hwp.header.gzipped?
p hwp.doc_info
p hwp.doc_info.char_shapes.length
# hwp.doc_info.char_shapes.each { |shape| p shape }

#p hwp.bodytext
#p hwp.bodytext.sections
#p hwp.bodytext.sections[0]
#p hwp.bodytext.sections.each { |id, data| }

