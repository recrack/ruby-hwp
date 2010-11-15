# (주)한글과컴퓨터의 한컴오피스 hwp 문서 파일 구조 공개정책에 따라 이루어졌습니다.
# 이렇게 말하면 ruby-hwp 개발자가 (주)한글과컴퓨터社와 어떤 관계가 있는 것처럼 오해받을 수 있지만
# hwp 스펙 문서 11쪽 저작권 관련 내용을 보면 이렇게 표시하라고 해서 이렇게 표시했을 뿐입니다.
# ruby-hwp는 (주)한글과컴퓨터社가 만든 것이 아니며, (주)한글과컴퓨터社가 지원하지 않으며, (주)한글과컴퓨터社가 유지보수하지 않습니다.
# Note that ruby-hwp is not manufactured, approved, supported, maintained by Hancom Inc.
# ruby-hwp 개발자는 (주)한글과컴퓨터社와 아무런 관련이 없습니다.
# ruby-hwp 및 ruby-hwp 관련 문서 내용을 사용하여 발생된 모든 결과에 대하여 책임지지 않습니다.
# NO WARRANTY

require 'iconv'
require 'stringio'
require 'hwp/datatypes'

module Record;end
module Record
	class DocInfo
		attr_reader :char_shapes
		def initialize(dirent, header)
			if header.gzipped?
				z = Zlib::Inflate.new(-Zlib::MAX_WBITS)
				@doc_info = StringIO.new(z.inflate dirent.read)
				z.finish; z.close
			else
				@doc_info = StringIO.new(dirent.read)
			end

			@char_shapes = []

			parser = HWP::Parser.new @doc_info
			while parser.has_next?
				response = parser.pull
				case response.class.to_s
				when "Record::DocInfo::CharShape"
					@char_shapes << response
				end
			end
		end
	end

	class DocInfo::DocumentProperties
		def initialize data
			# 스펙 불일치
			data.unpack("SSSSSSSIII")
		end
	end

	class DocInfo::IDMappings
		def initialize data
			# 스펙 불일치
		end
	end

	class DocInfo::BinData
		def initialize data
			#p data.bytesize
			#p data.unpack("s30")
		end
	end

	class DocInfo::FaceName
		def initialize data
			# 스펙 불일치
			#p data.bytesize
			io = StringIO.new data
			property = io.read(1)
			len1 = (io.read 2).unpack("s")[0]
			name = Iconv.iconv('utf-8', 'utf-16', io.read(len1 * 2))[0]
			#substitute_type = io.read 1
			#p len2 = (io.read 2).unpack("s")[0]
			#p substitute_name = io.read(len2 * 2)#.unpack("S*").pack("C*")
			# 스펙 불일치
			type = io.read 10
			len3 = (io.read 2).unpack("s")[0]
			default_name = io.read(len3 * 2).unpack("S*").pack("C*")
		end
	end

	class DocInfo::BorderFill
		def initialize data
		end
	end

	class DocInfo::CharShape
		include Datatype

		def initialize data
			@fields = {
				word(7)		=>	:face_id,
				uint8(7)	=>	:width_letter,
				int8(7)		=>	:space_between_letters,
				uint8(7)	=>	:rel,
				int8(7)		=>	:pos,
				uint32		=>	:size, # 1000 = 10 px
				uint32		=>	:prop,
				int8		=>	:space_between_shadows1,
				int8		=>	:space_between_shadows1,
				colorref	=>	:color_letter,
				colorref	=>	:color_underline,
				colorref	=>	:color_shade,
				colorref	=>	:color_shadow,
				#uint16		=>	:char_shape_border_fill_id,
				#colorref	=>	:color_cancel_line
			}
			decode data,@fields
		end

		def size
			@size[0]
		end
	end

	class DocInfo::TabDef
		def initialize data
		end
	end

	class DocInfo::Numbering
		def initialize data
		end
	end

	class DocInfo::Bullet
		def initialize data
		end
	end

	class DocInfo::ParaShape
		def initialize data
		end
	end

	class DocInfo::Style
		def initialize data
		end
	end

	class DocInfo::DocData
		def initialize data
		end
	end

	class DocInfo::DistributeDocData
		def initialize data
		end
	end

	class DocInfo::Reserved
		def initialize data
		end
	end

	class DocInfo::CompatibleDocument
		def initialize data
		end
	end

	class DocInfo::LayoutCompatibility
		def initialize data
		end
	end

	class DocInfo::ForbiddenChar
		def initialize data
		end
	end
end

module Record::Data
	class Reserved
	end

	class FootnoteShape
		def initialize data
			#p self
			# 스펙 문서 57쪽 크기 불일치 26 != 28
			#p data.unpack("ISSSSSSSSCCIS") # 마지막 2바이트 S, 총 28바이트
		end
	end

	class PageBorderFill
		def initialize data
			#p self
			# 스펙 문서 58쪽 크기 불일치 12 != 14
			#p data.unpack("ISSSSS") # 마지막 2바이트 S, 총 14바이트
		end
	end

	class EQEdit
		# TODO DOT 훈DOT 민 DOT 정 DOT 음
		def initialize data
			io = StringIO.new(data)
			property = io.read(4).unpack("I")	# INT32
			len = io.read(2).unpack("s")[0]	# WORD
			#io.read(len * 2).unpack("S*").pack("U*")		# WCHAR
			@script = Iconv.iconv("utf-8", "utf-16", io.read(len * 2))[0].chomp		# WCHAR
			#p unknown = io.read(2).unpack("S")	# 스펙 50쪽과 다름
			#p size = io.read(4).unpack("I")		# HWPUNIT
			#p color = io.read(4).unpack("I")	# COLORREF
			#p baseline = io.read(2).unpack("s")	# INT16
		end

		def to_s
			@script
		end
	end

	class ParaHeader
		attr_accessor(
			:chars,
			:control_mask,
			:ref_para_shape_id,
			:ref_para_style_id,
			:a_kind_of_column,
			:num_char_shape,
			:num_range_tag,
			:num_align,
			:para_instance_id)

		def initialize data
			@chars,				@control_mask,
			@ref_para_shape_id,	@ref_para_style_id,
			@a_kind_of_column,	@num_char_shape,
			@num_range_tag,		@num_align,
			@para_instance_id = data.unpack("IISCCSSSI")
		end
	end

	class ParaText
		attr_accessor :utf8_text
		def initialize data
			begin
				# 8 * 2 bytes
				# \k 를 사용하여 짝(pair)까지 맞아야 하는 정규표현식이다.  \1 을 사용해도 된다.
				filtered_data = data.gsub(/(?<ctrl>[\x01-\x08]\x00)............\k<ctrl>/m, "")
				# tab
				filtered_data.gsub!(/(?<ctrl>\x09\x00)............\k<ctrl>/m, "\t\x00")
				# 1 * 2 bytes
				filtered_data.gsub!(/\x0a\x00/m, "")
				# 8 * 2 bytes
				filtered_data.gsub!(/(?<ctrl>[\x0b|\x0c]\x00)............\k<ctrl>/m, "")
				# 1 * 2 bytes
				filtered_data.gsub!(/\x0d\x00/m, "")
				# 8 * 2 bytes
				filtered_data.gsub!(/(?<ctrl>[\x0e-\x17]\x00)............\k<ctrl>/m, "")
				# 1 * 2 bytes
				filtered_data.gsub!(/[\x18-\x1d]\x00/m, "")
				# space
				filtered_data.gsub!(/\x1e\x00/m, " \x00")
				filtered_data.gsub!(/\x1f\x00/m, "")

				# 유니코드 문자 교정, 한자 영역 등의 다른 영영과 겹칠지도 모른다.
				# 초성 filler utf-16 값 "_\x11"
				filtered_data.gsub!(/\x84\xF7/m, "_\x11")

				# 중성 ㅘ		utf-16 값 "j\x11"
				filtered_data.gsub!(/\x1C\xF8/m, "j\x11")
				# 중성 ㅙ		utf-16 값 "k\x11"
				filtered_data.gsub!(/\x1D\xF8/m, "k\x11")

				# 중성 ㅝ		utf-16 값 "o\x11"
				filtered_data.gsub!(/4\xF8/m, "o\x11")

				# 종성 ㅆ		utf-16 값 "\xBB\x11"
				filtered_data.gsub!(/\xCD\xF8/m, "\xBB\x11")

				#p data
				#p filtered_data
				@utf8_text = Iconv.iconv("utf-8", "utf-16", filtered_data)[0].chomp
			rescue
				p data
				raise "ERROR: Iconv.iconv(\"utf-8\", \"utf-16\", data)[0].chomp"
			end
		end

		def to_s
			@utf8_text
		end
	end

	class ParaCharShape
		attr_accessor :m_pos, :m_id

		def initialize data
			@m_pos = []
			@m_id = []
			n = data.bytesize / 4
			array = data.unpack("I" * n)
			array.each_with_index do |element, i|
				@m_pos << element if (i % 2) == 0
				@m_id  << element if (i % 2) == 1
			end
		end
	end

	class ParaLineSeg
		# 스펙 문서에 안 나와 있음
	end

	class ParaRangeTag
		attr_accessor :start, :end, :tag
		def initialize data
			@start, @end, @tag = data.unpack("IIb*")
		end
	end

	class CtrlHeader
		attr_accessor :ctrl_id
		def initialize data
		# 스펙 문서 오류, 사이즈 28 나온다.
			#p self
			#p data
		end
	end

	class PageDef
		def initialize data
			# I | HWPUNIT unsigned int
			horizontal_size,	vertical_size,	left_margin,
			right_margin,		top_margin,		bottom_margin,
			head_margin,		foot_margin,	binding_margin,
			property = data.unpack("IIIIIIIIII")
			#print "PageDef: "; p array
		end
	end

	class ListHeader
		attr_accessor :num_para, :property
		def initialize data
		# 스펙 문서 오류, 사이즈 18 나온다.
#			p self
#			p data
#			p @num_para = data[0..1].unpack("s*")[0]
#			p @property = data[2..5].unpack("b*")[0]
		end
	end

	class CtrlData
		attr_accessor :var
		def initialize data
			@var = data # 표 45 참조
		end
	end

# 스펙 문서 43 쪽 표 70
# UINT32 4바이트
	class Table
		def initialize data
			@common_property,	@num_row,	@num_col,
			@cell_spacing,		@num_col = data.unpack("ISSSS")
		end
	end

	class PropertyOfTableProperty
		def initialize
		end
	end

	class InfoInsideMargin
		def initialize
			@left
			@right
			@upper
			@bottom
		end
	end

	class FieldProperty
		def initialize
			@addr_col_start
			@addr_row_start
			@addr_col_end
			@addr_row_end
			@border_fill_id
		end
	end

	class CellList
		def initialize
			@header_para_list
			@cell_property
		end
	end

	class CellProperty
		def initialize
			@addr_cell_col
			@addr_cell_row
			@num_col_merge
			@num_row_merge
			@width
			@height
			@margins
			@border_and_backgroud_id
		end
	end
end
