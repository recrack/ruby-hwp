#(주)한글과컴퓨터의 한컴오피스 hwp 문서 파일 구조 공개정책에 따라 이루어졌습니다.
#이렇게 말하면 libhwp 개발자가 (주)한글과컴퓨터社와 어떤 관계가 있는 것처럼 오해받을 수 있지만
#hwp 스펙 문서 11쪽 저작권 관련 내용을 보면 이렇게 표시하라고 해서 이렇게 표시했을 뿐입니다.
#libhwp는 (주)한글과컴퓨터社가 만든 것이 아니며, (주)한글과컴퓨터社가 지원하지 않으며, (주)한글과컴퓨터社가 유지보수하지 않습니다.
#Note that libhwp is not manufactured, approved, supported, maintained by Hancom Inc.
#libhwp 개발자는 (주)한글과컴퓨터社와 아무런 관련이 없습니다.
#libhwp 및 libhwp 관련 문서 내용을 사용하여 발생된 모든 결과에 대하여 책임지지 않습니다.
#NO WARRANTY

module Record;end

module Record::Data
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
			array = data.unpack("IISCCSSSI")
			@chars = array[0]
			@control_mask = array[1]
			@ref_para_shape_id = array[2]
			@ref_para_style_id = array[3]
			@a_kind_of_column = array[4]
			@num_char_shape = array[5]
			@num_range_tag = array[6]
			@num_align = array[7]
			@para_instance_id = array[8]
#			puts "@chars = #{array[0]}"
#			puts "@control_mask = #{array[1]}"
#			puts "@ref_para_shape_id = #{array[2]}"
#			puts "@ref_para_style_id = #{array[3]}"
#			puts "@a_kind_of_column = #{array[4]}"
#			puts "@num_char_shape = #{array[5]}"
#			puts "@num_range_tag = #{array[6]}"
#			puts "@num_align = #{array[7]}"
#			puts "@para_instance_id = #{array[8]}"
		end
	end

	class ParaText
		attr_accessor :raw_text, :utf8_text_wo_ctrl, :utf8_text_w_ctrl
		def initialize data
			begin
				# [\x01-\x1f]\x00 로 시작해서 시작한 패턴으로 끝나는 문자열 감지
				# \k<ctrl> 를 사용하여 짝(pair)까지 맞아야 하는 정규표현식이다.  \1 을 사용해도 된다.
				filtered_data = data.gsub(/(?<ctrl>[\x01-\x1f]\x00)............\k<ctrl>/, "")
				puts @utf8_text = Iconv.iconv("utf-8", "utf-16", filtered_data)[0].chomp
			rescue
				p data
				puts "ERROR: Iconv.iconv(\"utf-8\", \"utf-16\", data)[0].chomp"
			end
		end
	end

	class ParaCharShape
		attr_accessor :m_pos, :m_id

		def initialize data
			(data.size/8).times do |i|
				@m_pos = data[(i * 8)..(i*8+3)].unpack("I*")[0] # 4 bytse
				@m_id  = data[(i*8+4)..(i*8+7)].unpack("I*")[0] # 4 bytes
				#puts "m_pos=#{@m_pos}, m_id=#{@m_id}"
			end
		end
	end

	class ParaLineSeg
	end

	class ParaRangeTag
		attr_accessor :start, :end, :tag
		def initialize data
			@start = data[0..3].unpack("I*")[0]
			@end = data[4..7].unpack("I*")[0]
			@tag = data[8..11].unpack("b*")[0]
		end
	end

	class CtrlHeader
		attr_accessor :ctrl_id
		def initialize data
		# 스펙 문서 오류
			@ctrl_id = data
		end
	end

	class PageDef
		def initialize data
			# I | HWPUNIT unsigned int
			array = data.unpack("IIIIIIIIII")
			horizontal_size = array[0]
			vertical_size = array[1]
			left_margin = array[2]
			right_margin = array[3]
			top_margin = array[4]
			bottom_margin = array[5]
			head_margin = array[6]
			foot_margin = array[7]
			binding_margin = array[8]
			property = array[9]
			#print "PageDef: "; p array
		end
	end

	class ListHeader
		attr_accessor :num_para, :property
		def initialize data
			@num_para = data[0..1].unpack("I*")[0]
			@property = data[2..5].unpack("b*")[0]
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
			str_io = StringIO.new data
			@common_property = str_io.read(4)
			@num_row = str_io.read(2).unpack("S*")[0]
			@num_col = str_io.read(2).unpack("S*")[0]
			@cell_spacing = str_io.read(2).unpack("S*")[0]
			@num_col = str_io.read(2).unpack("S*")[0]
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
