# coding: utf-8
# apt-get install libole-ruby
# or gem install ruby-ole
#(주)한글과컴퓨터의 한컴오피스 hwp 문서 파일 구조 공개정책에 따라 이루어졌습니다.
#이렇게 말하면 libhwp 개발자가 (주)한글과컴퓨터社와 어떤 관계가 있는 것처럼 오해받을 수 있지만
#hwp 스펙 문서 11쪽 저작권 관련 내용을 보면 이렇게 표시하라고 해서 이렇게 표시했을 뿐입니다.
#libhwp는 (주)한글과컴퓨터社가 만든 것이 아니며, (주)한글과컴퓨터社가 지원하지 않으며, (주)한글과컴퓨터社가 유지보수하지 않습니다.
#Note that libhwp is not manufactured, approved, supported, maintained by Hancom Inc.
#libhwp 개발자는 (주)한글과컴퓨터社와 아무런 관련이 없습니다.
#libhwp 및 libhwp 관련 문서 내용을 사용하여 발생된 모든 결과에 대하여 책임지지 않습니다.
#NO WARRANTY

require 'iconv'
require 'ole/storage'
require 'zlib'
require 'stringio'
require './data.rb'
require './tags.rb'

module HWP
# unpack, pack
# C     |  Unsigned char # 1 byte
# I     |  Unsigned integer # 4 bytes
# L     |  Unsigned long
# S     |  Unsigned short # 2 bytes

# c     |  char # 1 byte
# i     |  integer # 4 bytes
# l     |  long
# s     |  short # 2 bytes

# unpack, pack
# C     |  UINT8  # 1 byte
# I     |  UINT32 # 4 bytes
# L     |  Unsigned long
# S     |  UINT16 # 2 bytes

# c     |  char # 1 byte
# i     |  integer # 4 bytes
# l     |  long
# s     |  short # 2 bytes

# typedef unsigned char  UINT8;		1 byte
# typedef unsigned short UINT16;	2 bytes
# typedef unsigned int   UINT32;	4 bytes

	BYTE = 1
	WORD = 2
	DWORD = 4
	WCHAR = 2
	HWPUNIT = 4
	SHWPUNIT = 4
	UINT8 = 1
	UINT16 = 2
	UINT32 = 4
	UINT = UINT32
	INT8 = 1
	INT16 = 2
	INT32 = 4
	HWPUNIT16 = 2
	COLORREF = 4

	class Reader
		attr_reader :file_header, :doc_info, :body_text, :view_text,
					:summary_info, :bin_data, :prv_text, :pre_image,
					:doc_options, :scripts, :xml_template, :doc_history

		def initialize file
			@ole = Ole::Storage.open(file, 'rb')
			_entries = @ole.dir.entries('/') - ['.', '..']

			ordered_entries = [ "FileHeader", "DocInfo", "BodyText", "ViewText",
						"\005HwpSummaryInformation", "BinData", "PrvText", "PrvImage",
						"DocOptions", "Scripts", "XMLTemplate", "DocHistory" ]

			ordered_entries.each do |entry|
				if _entries.include? entry
					dirent = @ole.dirent_from_path entry
					case entry
					when "FileHeader"	then @file_header = FileHeader.new dirent
					when "DocInfo"		then @doc_info = Record::DocInfo.new dirent
					when "BodyText"		then @body_text = Record::BodyText.new dirent
					when "ViewText"		then @view_text = Record::ViewText.new dirent
					when "\005HwpSummaryInformation"
						@summary_info = Record::HwpSummaryInformation.new dirent
					when "BinData"		then @bin_data = Record::BinData.new dirent
					when "PrvText"		then @prv_text = Record::PrvText.new dirent
					when "PrvImage"		then @prv_image = Record::PrvImage.new dirent
					when "DocOptions"	then @doc_options = Record::DocOptions.new dirent
					when "Scripts"		then @scripts = Record::Scripts.new dirent
					when "XMLTemplate"	then @xml_template = Record::XMLTemplate.new dirent
					when "DocHistory"	then @doc_history = Record::DocHistory.new dirent
					else puts "unknown tags"
					end
					_entries = _entries - [entry]
				end
			end

			unless _entries.empty?
				puts "unknown tags"
				p _entries
			end
		end

		def close
			@ole.close
		end

		def to_s
			@file_header.to_s
			@doc_info.to_s
			@bodytext.to_s
			@view_text.to_s
			@summary_info.to_s
			@bin_data.to_s
			@prv_text.to_s
			@pre_image.to_s
			@doc_options.to_s
			@scripts.to_s
			@xml_template.to_s
			@doc_history.to_s
		end
	end

	class CommonCtrl
#	표		tbl
#	선		lin
#	사각형	rec
#	타원		ell
#	호		arc
#	다각형	pol
#	곡선		cur
#	한글97수식	eqed
#	그림			pic
#	ole			ole
#	묶음개체		con
	end

	class CommonProperty
#		@common_property # 36 bytes
		def initialize data
			str_io = StringIO.new data
			@ctrl_id = str_io.read(4)
			@property = str_io.read(4).unpack("b*")[0]
			@hoz_offset = str_io.read(4)
			@ver_offset = str_io.read(4)
			@width = str_io.read(4)
			@height = str_io.read(4)
			@z_order = str_io.read(2)
			@margins = str_io.read(2*4)
			@instance_id = str_io.read(4)
			@len = str_io.read(2)
			@chars = str_io.read(2*@len) # 끝까지 읽는다
		end
#		@caption_list # if any
	end
end

class FileHeader
	attr_accessor :signature, :version, :property, :reversed
	def initialize dirent
		data = dirent.read
		@signature	= data[0..31]
		@version	= data[32..35].reverse.unpack("C*").join(".")
		@property	= data[36..39].unpack("b*")[0]
		@reversed	= data[40..255]
	end

	method_names = ['gzipped?', 'encrypted?', 'distribute?', 'script?',
					'drm?', 'xmltemplate?', 'history?', 'sign?',
					'certificate_encrypt?', 'sign_spare?', 'certificate_drm?', 'ccl?']

	method_names.each_with_index do |method_name, i|
		define_method(method_name) do
			@property[i] == '1' ? true : false
		end
	end
end

module Record
	class DocInfo;end
	class PrvText;end
	class Scripts;end
	class PrvImage;end
	class DocOptions;end
	class HwpSummaryInformation;end
	class Header
		attr_accessor :tag_id, :level, :size

		def initialize bytes=nil
			lsb_first = bytes.unpack("b*")[0] # 이진수, LSB first, bit 0 가 맨 앞에 온다.

			if lsb_first
				@tag_id	= lsb_first[0..9].reverse.to_i(2) # 9~0
				@level	= lsb_first[10..19].reverse.to_i(2) # 19~10
				@size	= lsb_first[20..31].reverse.to_i(2) # 31~20
			end
		end
	end

	class BodyText
		attr_accessor :bodytext
		def initialize(dirent, gzipped=true)
			@gzipped = gzipped
			@dirent = dirent
			@bodytext = []
		end

		def parse
			if @gzipped
				@dirent.each_child do |section|
					z = Zlib::Inflate.new(-Zlib::MAX_WBITS)
					@bodytext << StringIO.new(z.inflate section.read)
					z.finish
					z.close
				end
			else
				@dirent.each_child do |section|
					@bodytext << StringIO.new(section)
				end
			end

			@bodytext.each do |section|
				while(bytes = section.read(HWP::DWORD))  # 레코드 헤더를 읽는다
					header = Record::Header.new(bytes)
					data = section.read(header.size)

					case HWPTAGS[header.tag_id]
					when :HWPTAG_PARA_HEADER
						p HWPTAGS[header.tag_id]
						Record::Data::ParaHeader.new data
					when :HWPTAG_PARA_TEXT
						p HWPTAGS[header.tag_id]
						p data
						Record::Data::ParaText.new data
					when :HWPTAG_PARA_CHAR_SHAPE
						p HWPTAGS[header.tag_id]
						Record::Data::ParaCharShape.new data
					when :HWPTAG_PARA_LINE_SEG
						p HWPTAGS[header.tag_id]
						p data
					when :HWPTAG_PARA_RANGE_TAG
						p HWPTAGS[header.tag_id]
						p data
					when :HWPTAG_CTRL_HEADER
						p HWPTAGS[header.tag_id]
						p data
						Record::Data::CtrlHeader.new data
					when :HWPTAG_LIST_HEADER
						p HWPTAGS[header.tag_id]
						p data
					when :HWPTAG_PAGE_DEF
						p HWPTAGS[header.tag_id]
						Record::Data::PageDef.new data
					when :HWPTAG_FOOTNOTE_SHAPE
						p HWPTAGS[header.tag_id]
						p data.size
					when :HWPTAG_PAGE_BORDER_FILL
						p HWPTAGS[header.tag_id]
						p data
					when :HWPTAG_SHAPE_COMPONENT
						p HWPTAGS[header.tag_id]
						p data
					when :HWPTAG_TABLE
						p HWPTAGS[header.tag_id]
						p data
						Record::Data::Table.new data
					when :HWPTAG_SHAPE_COMPONENT_LINE
						p HWPTAGS[header.tag_id]
						p data
					when :HWPTAG_SHAPE_COMPONENT_RECTANGLE
						p HWPTAGS[header.tag_id]
						p data
					when :HWPTAG_SHAPE_COMPONENT_ELLIPSE
						p HWPTAGS[header.tag_id]
						p data
					when :HWPTAG_SHAPE_COMPONENT_ARC
						p HWPTAGS[header.tag_id]
						p data
					when :HWPTAG_SHAPE_COMPONENT_POLYGON
						p HWPTAGS[header.tag_id]
						p data
					when :HWPTAG_SHAPE_COMPONENT_CURVE
						p HWPTAGS[header.tag_id]
						p data
					when :HWPTAG_SHAPE_COMPONENT_OLE
						p HWPTAGS[header.tag_id]
						p data
					when :HWPTAG_SHAPE_COMPONENT_PICTURE
						p HWPTAGS[header.tag_id]
						p data
					when :HWPTAG_SHAPE_COMPONENT_CONTAINER
						p HWPTAGS[header.tag_id]
						p data
					when :HWPTAG_CTRL_DATA
						Record::Data::CtrlData.new data
					when :HWPTAG_EQEDIT
						p HWPTAGS[header.tag_id]
						p data
					when :RESERVED
						p HWPTAGS[header.tag_id]
						p data
					when :HWPTAG_SHAPE_COMPONENT_TEXTART
						p HWPTAGS[header.tag_id]
						p data
					when :HWPTAG_FORM_OBJECT
						p HWPTAGS[header.tag_id]
						p data
					when :HWPTAG_MEMO_SHAPE
						p HWPTAGS[header.tag_id]
						p data
					when :HWPTAG_MEMO_LIST
						p HWPTAGS[header.tag_id]
						p data
					when :HWPTAG_CHART_DATA
						p HWPTAGS[header.tag_id]
						p data
					when :HWPTAG_SHAPE_COMPONENT_UNKNOWN
						p HWPTAGS[header.tag_id]
						p data
					else
						p HWPTAGS[header.tag_id]
						p data
						raise "unknown tag"
					end
				end
			end
		end
	end # of (class BodyText)
end # of (module Record)


