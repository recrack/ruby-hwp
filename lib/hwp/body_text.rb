module Record
    class BodyText
		attr_accessor :para_headers

		def initialize(dirent, header)
			@dirent = dirent
			@para_headers = []

			if header.compress?
				@dirent.each_child do |section|
					z = Zlib::Inflate.new(-Zlib::MAX_WBITS)
					parser = HWP::Parser.new StringIO.new(z.inflate section.read)
					z.finish
					z.close
					# TODO table 구조
					stack = [parser.pull]
					@para_headers << stack[-1]
					while parser.has_next?
						current = parser.pull
						case current.level - stack[-1].level
						# 깊이 1 증가
						when 1
							parent = stack[-1]
							stack.push current
							case parent
							when Record::Section::ParaHeader
								case current
								when Record::Section::ParaText
									#p stack[-3]
									parent.para_text = current
								when Record::Section::ParaCharShape
							 		parent.para_char_shape = current
								else
									STDERR.puts "#{current.class.name}: not implemented"
								end
							when Record::Section::Modeller
								case current
								when Record::Section::PageDef
									parent.page_defs << current
								when Record::Section::ListHeader
									parent.append_list_header current
								when Record::Section::Table
									parent.append_table current
								else
									STDERR.puts "#{current.class.name}: not implemented"
								end
							else
								STDERR.puts "#{parent.class.name}: not implemented"
							end
						# 같은 깊이
						when 0
							stack.pop
							parent = stack[-1]
							stack.push current
							case parent
							when Record::Section::ParaHeader
								case current
								when Record::Section::ParaCharShape
									parent.para_char_shape = current
								when Record::Section::ParaLineSeg
									parent.para_line_seg = current
								when Record::Section::Modeller
									case current.ctrl_id
									when 'tbl '
										parent.table = current.text_table
										parent.ctrl_headers << current
									else
										parent.ctrl_headers << current
									end
								else
									STDERR.puts "#{current.class.name}: not implemented"
								end
							when Record::Section::Modeller
								case current
								when Record::Section::FootnoteShape
									parent.footnote_shapes << current
								when Record::Section::PageBorderFill
									parent.page_border_fills << current
								when Record::Section::ParaHeader
									parent.append_para_header current
								when Record::Section::ListHeader
									parent.append_list_header current
								else
									STDERR.puts "#{current.class.name}: not implemented"
								end
							else
								STDERR.puts "#{parent.class.name}: not implemented"
							end
						# 깊이 1 이상 감소
						# level 은 10-bit 이므로 -1023 이 최소값
						when -1023..-1
							stack.pop((current.level - stack[-1].level).abs)
							stack.pop
							parent = stack[-1]
							stack.push current
							case parent
							when Record::Section::ParaHeader
								case current
								when Record::Section::Modeller
									case current.ctrl_id
									when 'tbl '
										parent.table = current.text_table
										parent.ctrl_headers << current
									else
										parent.ctrl_headers << current
									end
								else
									STDERR.puts "#{current.class.name}: not implemented"
								end
							when Record::Section::Modeller
								case current
								when Record::Section::ListHeader
									parent.append_list_header current
								when Record::Section::ParaHeader
									parent.append_para_header current
								else
									STDERR.puts "#{current.class.name}: not implemented"
								end
							# level 0 의 ParaHeader가 교체될 경우 nil 값이 나온다.
							when nil
								case current
								when Record::Section::ParaHeader
									@para_headers << current
								else
									STDERR.puts "#{current.class.name}: not implemented"
								end
							else
								STDERR.puts "#{parent.class.name}: not implemented"
							end
						else # 깊이가 1이상 증가하는 경우, 에러 발생
							p(current.level - stack[-1].level)
							STDERR.puts "#{current.class.name}: not implemented"
						end
					end # while
				end # @dirent.each_child
			else
				@dirent.each_child do |section|
				# TODO
				end
			end # if

			# debugging code
			@para_headers.each do |para_header|
				para_header.debug
				para_header.para_text.debug if para_header.para_text

				para_header.para_char_shape.debug

				para_header.para_line_seg.debug

				if para_header.table
					para_header.table.rows.each do |row|
						row.cells.each do |cell|
							cell.para_headers.each do |para_header|
								p para_header.para_text
							end
						end
					end
				end

				para_header.ctrl_headers.each do |ctrl_header|
					ctrl_header.debug
					ctrl_header.page_defs.each do |page_def|
						page_def.debug
					end

					ctrl_header.footnote_shapes.each do |footnote_shape|
						footnote_shape.debug
					end

					ctrl_header.page_border_fills.each do |page_border_fill|
						page_border_fill.debug
					end

					ctrl_header.list_headers.each do |list_header|
						list_header.debug
					end

					ctrl_header.para_headers.each do |para_header|
						para_header.debug
						# 재귀적 용법의 필요성을 느낀다.
						para_header.para_text.debug if para_header.para_text

						para_header.para_char_shape.debug

						para_header.para_line_seg.debug

						para_header.ctrl_headers.each do |ctrl_header|
							ctrl_header.debug
						end
					end # ctrl_header.para_headers.each
				end # para_header.ctrl_headers.each
			end # @para_headers.each
		end # initialize
	end # BodyText
end


module Record::Section
	class ParaHeader
		attr_reader :chars,
					:control_mask,
					:ref_para_shape_id,
					:ref_para_style_id,
					:column_type,
					:num_char_shape,
					:num_range_tag,
					:num_align,
					:para_instance_id,
					:level
		attr_accessor :para_text,
					  :para_char_shape,
					  :para_line_seg,
					  :ctrl_headers,
					  :table # para_header 에 ctrl_header 가 1개만 오는 것으로 추정한다.

		def initialize data, level
			@level = level
			@chars,
			@control_mask,
			@para_shape_id,
			@para_style_id,
			@column_type,
			@num_char_shape,
			@num_range_tag,
			@num_align,
			@para_instance_id = data.unpack("vVvvvvvvV")

			# para_text, para_char_shape 가 1개 밖에 안 오는 것 같으나 확실하지 않으니
			# 배열로 처리한다. 추후 ParaText, ParaCharShape 클래스를 ParaHeader 이나
			# 이와 유사한 자료구조(예를 들면, Paragraph)에 내포하는 것을 고려한다.
			# para_header 에는 para_text 가 1개만 오는 것 같다.
			@ctrl_headers = []
		end

		def debug
			puts "\t"*@level + "ParaHeader:"
		end
	end

	class ParaText
		attr_reader :level

		def initialize data, level
			@level = level
			s_io = StringIO.new data

			@bytes = []

			while(ch = s_io.read(2))
				case ch.unpack("v")[0]
				# 2-byte control string
				when 0,10,13,24,25,26,27,28,29,31
					#@bytes << ch.unpack("v")[0]
				when 30 # 0x1e record separator (RS)
					@bytes << 0x20 # 임시로 스페이스로 대체

				# 16-byte control string, inline
				when 4,5,6,7,8,19,20
					s_io.pos += 14
				when 9 # tab
					@bytes << 9
					s_io.pos += 14

				# 16-byte control string, extended
				when 1,2,3,11,12,14,15,16,17,18,21,22,23
					s_io.pos = s_io.pos + 14
				#when 11 # 그리기 개체/표
				# 포인터가 있다고 하는데 살펴보니 tbl의 경우 포인터가 없고 ctrl id 만 있다.
				#	p s_io.read(14).unpack("v*")
				# TODO mapping table
				# 유니코드 문자 교정, 한자 영역 등의 다른 영역과 겹칠지도 모른다.
				# L filler utf-16 값 "_\x11"
				when 0xf784 # "\x84\xf7
					@bytes << 0x115f
				# V ㅘ		utf-16 값 "j\x11"
				when 0xf81c # "\x1c\xf8"
					@bytes << 0x116a
				# V ㅙ		utf-16 값 "k\x11"
				when 0xf81d # "\x1d\xf8"
					@bytes << 0x116b
				# V ㅝ		utf-16 값 "o\x11"
				when 0xf834 # "\x34\xf8" "4\xf8"
					@bytes << 0x116f
				# T ㅆ		utf-16 값 "\xBB\x11"
				when 0xf8cd # "\xcd\xf8"
					@bytes << 0x11bb
				else
					@bytes << ch.unpack("v")[0]
				end
			end
			s_io.close
		end

		def to_s
			@bytes.pack("U*")
		end

		def debug
			puts "\t"*@level +"ParaText:" + to_s
		end
	end # class ParaText

	class ParaCharShape
		attr_accessor :m_pos, :m_id, :level
		# TODO m_pos, m_id 가 좀 더 편리하게 바뀔 필요가 있다.
		def initialize data, level
			@level = level
			@m_pos = []
			@m_id = []
			n = data.bytesize / 4
			array = data.unpack("V" * n)
			array.each_with_index do |element, i|
				@m_pos << element if (i % 2) == 0
				@m_id  << element if (i % 2) == 1
			end
		end

		def debug
			puts "\t"*@level +"ParaCharShape:" + @m_pos.to_s + @m_id.to_s
		end
	end

	# TODO REVERSE-ENGINEERING
	# 스펙 문서에는 생략한다고 나와 있다. hwp3.0 또는 hwpml 스펙에 관련 정보가 있는지 확인해야 한다.
	class ParaLineSeg
		attr_reader :level

		def initialize data, level
			@level = level
			@data = data
		end

		def debug
			puts "\t"*@level +"ParaLineSeg:"
		end
	end

	class ParaRangeTag
		attr_accessor :start, :end, :tag, :level
		def initialize data, level
			@level = level
			raise NotImplementedError.new "Record::Section::ParaRangeTag"
			#@start, @end, @tag = data.unpack("VVb*")
		end
	end

	# TODO REVERSE-ENGINEERING
	class Modeller
		attr_reader :ctrl_id, :level
		attr_accessor :page_defs, :footnote_shapes, :page_border_fills,
					  :list_headers, :para_headers, :tables, :text_table
		def initialize data, level
			@level = level
			s_io = StringIO.new data
			@ctrl_id = s_io.read(4).unpack("C4").pack("U*").reverse
			common = ['tbl ','$lin','$rec','$ell','$arc','$pol',
					  '$cur','eqed','$pic','$ole','$con']

			begin
				if common.include? @ctrl_id
					bit = s_io.read(4).unpack("b32")
					v_offset = s_io.read(4).unpack("V")
					h_offset = s_io.read(4).unpack("V")
					width = s_io.read(4).unpack("V")
					height = s_io.read(4).unpack("V")
					z = s_io.read(4).unpack("i")
					margins = s_io.read(2*4).unpack("v*")
					id = s_io.read(4).unpack("V")[0]
					len = s_io.read(2).unpack("v")[0]
					# 바이트가 남는다.
					s_io.close
				end
			rescue => e
				STDERR.puts e.message
			end
			# accessor
			@page_defs, @footnote_shapes, @page_border_fills = [], [], []
			@list_headers, @para_headers, @tables = [], [], []

			@result = case @ctrl_id
			when 'tbl '
				# TODO
				@text_table = Text::Table.new # 배열로 만들어야 할지도 모르겠다.
				#STDERR.puts "#{@ctrl_id}: not implemented"
			when '$lin'
				STDERR.puts "#{@ctrl_id}: not implemented"
			when '$rec'
				STDERR.puts "#{@ctrl_id}: not implemented"
			when '$ell'
				STDERR.puts "#{@ctrl_id}: not implemented"
			when '$arc'
				STDERR.puts "#{@ctrl_id}: not implemented"
			when '$pol'
				STDERR.puts "#{@ctrl_id}: not implemented"
			when '$cur'
				STDERR.puts "#{@ctrl_id}: not implemented"
			when 'eqed'
				STDERR.puts "#{@ctrl_id}: not implemented"
			when '$pic'
				STDERR.puts "#{@ctrl_id}: not implemented"
			when '$ole'
				STDERR.puts "#{@ctrl_id}: not implemented"
			when '$con'
				STDERR.puts "#{@ctrl_id}: not implemented"
			end
		end

		# @text_table은 임시로 만든 이름이다. 더 나은 API 설계를 할 것.
		def append_table table
			@tables << table
			@text_table.rows = Array.new(table.row_count).collect {Text::Table::Row.new}
			
			@text_table.rows.each do |row|
				row.cells = Array.new(table.col_count).collect {Text::Table::Cell.new}
			end
		end

		def append_list_header list_header
			if @ctrl_id == 'tbl '
				@col_addr = list_header.col_addr
				@row_addr = list_header.row_addr
				col_span = list_header.col_span
				row_span = list_header.row_span
				@text_table.rows[@row_addr].cells[@col_addr] = Text::Table::Cell.new
				@text_table.rows[@row_addr].cells[@col_addr].row_span = row_span
				@text_table.rows[@row_addr].cells[@col_addr].col_span = col_span
				if col_span > 1
					for i in @col_addr...(@col_addr+col_span)
						@text_table.rows[@row_addr].cells[i].covered = true
					end
				end
				if row_span > 1
					for i in @row_addr...(@row_addr+row_span)
						@text_table.rows[i].cells[@col_addr].covered = true
					end
				end
			else
				@list_headers << list_header
			end
		end

		def append_para_header para_header
			if @ctrl_id == 'tbl '
				@para_headers << para_header
				# FIXME 파라 헤더가 없는 것이 있다. 고쳐야 된다.
				# list_header 다음에 오는 연속된 para_header 에 대하여 올바르게 처리해야 한다.
				@text_table.rows[@row_addr].cells[@col_addr].para_headers << para_header
			else
				@para_headers << para_header
			end
		end

		def debug
			puts "\t"*@level +"CtrlHeader:" + @ctrl_id
		end
	end

	# TODO REVERSE-ENGINEERING
	# 리스트 헤더: Table 다음에 올 경우 셀 속성
	class ListHeader
		attr_reader :level, :num_para,
					# table cell
					:col_addr, :row_addr, :col_span, :row_span,
					:width, :height, :margins
		def initialize data, level
			@level = level
			s_io = StringIO.new data
			@num_para = s_io.read(2).unpack("v").pop
			bit = s_io.read(4).unpack("b32").pop
			# TODO 테이블 셀이 아닌 경우에 대한 처리가 필요하다. 또는 테이블 셀 감지
			s_io.pos = 8 # 셀 속성 시작 위치
			@col_addr,
			@row_addr,
			@col_span,
			@row_span,
			@width,
			@height,
			@margins = s_io.read.unpack("v4 V2 v4 v")
			#p data.bytesize
			# 4바이트가 남는다
			s_io.close
		end

		def debug
			puts "\t"*@level +"ListHeader:"
		end
	end

	class CtrlData
		attr_accessor :var, :level
		def initialize data, level
			@level = level
			STDERR.puts "{#self.class.name}: not implemented"
		end
	end

	# TODO REVERSE-ENGINEERING
	class Table
		attr_reader :level, :prop, :row_count, :col_count, :cell_spacing, :margins, :row_size, :border_fill_id
		def initialize data, level
			@level = level
			s_io = StringIO.new data
			@prop = s_io.read(4).unpack("V")
			@row_count = s_io.read(2).unpack("v")[0]
			@col_count = s_io.read(2).unpack("v")[0]
			@cell_spacing = s_io.read(2).unpack("v")
			@margins = s_io.read(2*4).unpack("v4")
			@row_size = s_io.read(2*row_count).unpack("v*")
			@border_fill_id = s_io.read(2).unpack("v")
			#valid_zone_info_size = s_io.read(2).unpack("v")[0]
			#zone_prop = s_io.read(10*valid_zone_info_size).unpack("v*")
			s_io.close
		end

		def debug
			puts "\t"*@level +"Table:"
		end
	end

	class ShapeComponent
		attr_reader :scale_matrices, :rotate_matrices, :level
		FLIP_TYPE = ['horz flip', 'vert flip']

		def initialize data, level
			@level = level
			@scale_matrices, @rotate_matrices = [], []
			s_io = StringIO.new data
			# NOTE ctrl_id 가 두 번 반복됨을 주의하자
			ctrl_id = s_io.read(4).unpack("C4").pack("U*").reverse
			ctrl_id = s_io.read(4).unpack("C4").pack("U*").reverse

			x_pos = s_io.read(4).unpack("I")[0]
			y_pos = s_io.read(4).unpack("I")[0]
			group_level = s_io.read(2).unpack("v")[0]
			local_file_version = s_io.read(2).unpack("v")[0]

			ori_width = s_io.read(4).unpack("V")[0]
			ori_height = s_io.read(4).unpack("V")[0]
			cur_width = s_io.read(4).unpack("V")[0]
			cur_height = s_io.read(4).unpack("V")[0]

			flip = FLIP_TYPE[s_io.read(4).unpack("V")[0]]

			angle = s_io.read(2).unpack("v")[0]
			center_x = s_io.read(4).unpack("V")[0]
			center_y = s_io.read(4).unpack("V")[0]

			count = s_io.read(2).unpack("v")[0]
			trans_matrix = s_io.read(48).unpack("E6")

			count.times do
				@scale_matrices  << s_io.read(48).unpack("E6")
				@rotate_matrices << s_io.read(48).unpack("E6")
			end
		end
	end

	class ShapeComponentLine
		attr_reader :level
		def initialize data, level
			@level = level
			STDERR.puts "{#self.class.name}: not implemented"
		end
	end

	class ShapeComponentRectangle
		attr_reader :level
		def initialize data, level
			@level = level
			STDERR.puts "{#self.class.name}: not implemented"
		end
	end

	class ShapeComponentEllipse
		attr_reader :level
		def initialize data, level
			@level = level
			STDERR.puts "{#self.class.name}: not implemented"
		end
	end

	class ShapeComponentArc
		attr_reader :level
		def initialize data, level
			@level = level
			STDERR.puts "{#self.class.name}: not implemented"
		end
	end

	class ShapeComponentPolygon
		attr_reader :level
		def initialize data, level
			@level = level
			STDERR.puts "{#self.class.name}: not implemented"
		end
	end

	class ShapeComponentCurve
		attr_reader :level
		def initialize data, level
			@level = level
			STDERR.puts "{#self.class.name}: not implemented"
		end
	end

	class ShapeComponentOLE
		attr_reader :level
		def initialize data, level
			@level = level
			STDERR.puts "{#self.class.name}: not implemented"
		end
	end

	# TODO REVERSE-ENGINEERING
	class ShapeComponentPicture
		attr_reader :level
		def initialize data, level
			@level = level
			data.unpack("V6sv4Vv vV vVvV")
		end
	end

	class ShapeComponentContainer
		attr_reader :level
		def initialize data, level
			@level = level
			STDERR.puts "{#self.class.name}: not implemented"
		end
	end

	class ShapeComponentTextArt
		attr_reader :level
		def initialize data, level
			@level = level
			STDERR.puts "{#self.class.name}: not implemented"
		end
	end

	class ShapeComponentUnknown
		attr_reader :level
		def initialize data, level
			@level = level
			STDERR.puts "{#self.class.name}: not implemented"
		end
	end

	class PageDef
		attr_reader :level
		def initialize data, level
			@level = level
			@data = data
			width,	height,
			left_margin,	right_margin,
			top_margin,		bottom_margin,
			header_margin,	footer_margin,
			gutter_margin,	property = @data.unpack("V*")
		end

		def debug
			puts "\t"*@level +"PageDef:"# + @data.unpack("V*").to_s
		end
	end

	# TODO REVERSE-ENGINEERING
	class FootnoteShape
		attr_reader :level
		def initialize data, level
			@level = level
			@data = data
			s_io = StringIO.new data
			s_io.read(4)
			s_io.read(2)
			s_io.read(2).unpack("CC").pack("U*")
			s_io.read(2)
			s_io.read(2)
			s_io.read(2)
			s_io.read(2)
			s_io.read(2)
			s_io.read(2)
			s_io.read(1)
			s_io.read(1)
			s_io.read(4)
			# 바이트가 남는다
			s_io.close
		end

		def debug
			puts "\t"*@level +"FootnoteShape:"# + @data.inspect
		end
	end

	class PageBorderFill
		attr_reader :level
		def initialize data, level
			@level = level
			# 스펙 문서 58쪽 크기 불일치 12 != 14
			#p data.unpack("ISSSSS") # 마지막 2바이트 S, 총 14바이트
		end

		def debug
			puts "\t"*@level +"PageBorderFill:"
		end
	end

	class EqEdit
		# TODO DOT 훈DOT 민 DOT 정 DOT 음
		attr_reader :level
		def initialize data, level
			@level = level
			io = StringIO.new(data)
			property = io.read(4).unpack("I")	# INT32
			len = io.read(2).unpack("s")[0]	# WORD
			#io.read(len * 2).unpack("S*").pack("U*")		# WCHAR
			@script = io.read(len * 2).unpack("v*").pack("U*")	# WCHAR
			#p unknown = io.read(2).unpack("S")	# 스펙 50쪽과 다름
			#p size = io.read(4).unpack("I")		# HWPUNIT
			#p color = io.read(4).unpack("I")	# COLORREF
			#p baseline = io.read(2).unpack("s")	# INT16
		end

		def to_s
			@script
		end
	end

	class Reserved
		attr_reader :level
		def initialize data, level
			@level = level
			STDERR.puts "{#self.class.name}: not implemented"
		end
	end

	class FormObject
		attr_reader :level
		def initialize data, level
			@level = level
			STDERR.puts "{#self.class.name}: not implemented"
		end
	end

	class MemoShape
		attr_reader :level
		def initialize data, level
			@level = level
			STDERR.puts "{#self.class.name}: not implemented"
		end
	end

	class MemoList
		attr_reader :level
		def initialize data, level
			@level = level
			STDERR.puts "{#self.class.name}: not implemented"
		end
	end

	class ChartData
		attr_reader :level
		def initialize data, level
			@level = level
			STDERR.puts "{#self.class.name}: not implemented"
		end
	end
end # Record::Section

module Text
	#table
	#	column
	#	column
	#	column
	#	row1
	#		cell1
	#		cell2
	#		cell3
	#	row2
	#		cell1
	#		cell2 number-rows-spanned = 2
	#		cell3
	#	row3
	#		cell1
	#		covered-table-cell
	#		cell3
	class Table
		attr_accessor :columns, :rows

		def initialize
			@columns = []
			@rows = []
		end

		class Row
			attr_accessor :cells
			def initialize
				@cells = []
			end
		end

		class Cell
			attr_accessor :para_headers, :row_span, :col_span, :covered
			def initialize
				@para_headers = []
				@covered = false
				@row_span = 1
				@col_span = 1
			end
		end
	end
end
