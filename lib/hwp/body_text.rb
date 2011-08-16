module Record
    class BodyText
        attr_accessor :para_headers

        def initialize(dirent, header)
            @dirent = dirent
            @para_headers = []

            @dirent.each_child do |section|
                if header.compress?
                    z = Zlib::Inflate.new(-Zlib::MAX_WBITS)
                    parser = HWP::Parser.new StringIO.new(z.inflate section.read)
                    z.finish
                    z.close
                else
                    parser = HWP::Parser.new StringIO.new(section.read)
                end
                
                parse(parser)
                #print_para_headers(self)
            end # @dirent.each_child
        end # initialize

        # <BodyText> ::= <Section>+
        # <Section> ::= <ParaHeader>+
        # 여기서는 <BodyText> ::= <ParaHeader>+ 로 간주함.
        def parse(parser)
            while parser.has_next?
                # stack 이 차 있으면 이전의 para header 이 끝난 후
                # stack 에 차 있는 para header 이 새롭게 시작됨.
                if parser.stack.empty?
                    parser.pull
                else
                    raise if parser.stack.pop != :HWPTAG_PARA_HEADER
                end

                # level == 0 인 파라헤더만 취한다. 그 밖의 것은 raise
                case parser.tag_id
                when :HWPTAG_PARA_HEADER
                    if parser.level == 0
                        para_header = Record::Section::ParaHeader.
                            new(parser.data, parser.level)
                        para_header.parse(parser)
                        @para_headers << para_header
                    else
                        raise "file corrupted?"
                    end
                else
                    # raise 발생하면 level == 0 인 뭔가가 있는 것임.
                    # v5.0 스펙에는 level == 0 인 것은 오로지 PARA_HEADER 임.
                    raise "unknown spec: #{parser.tag_id}"
                end
            end
        end

        def print_para_headers(obj)
            obj.para_headers.each do |para_header|
                puts " " * para_header.level + para_header.to_tag

                para_header.para_texts.each do |para_text|
                    puts " " * para_text.level + para_text.to_tag
                end

                para_header.para_char_shapes.each do |para_char_shape|
                    puts " " * para_char_shape.level + para_char_shape.to_tag
                end

                para_header.para_line_segs.each do |para_line_seg|
                    puts " " * para_line_seg.level + para_line_seg.to_tag
                end

                para_header.ctrl_headers.each do |ctrl_header|
                    puts " " * ctrl_header.level + ctrl_header.to_tag

                    ctrl_header.page_defs.each do |page_def|
                        puts " " * page_def.level + page_def.to_tag
                    end

                    ctrl_header.footnote_shapes.each do |footnote_shape|
                        puts " " * footnote_shape.level + footnote_shape.to_tag
                    end

                    ctrl_header.page_border_fills.each do |page_border_fill|
                        puts " " * page_border_fill.level + page_border_fill.to_tag
                    end

                    ctrl_header.list_headers.each do |list_header|
                        puts " " * list_header.level + list_header.to_tag
                    end

                    ctrl_header.eq_edits.each do |eq_edit|
                        puts " " * eq_edit.level + eq_edit.to_tag
                    end

                    # 재귀
                    print_para_headers(ctrl_header)
                end
            end
        end

        def debug(para_headers)
            # debugging code
            para_headers.each do |para_header|
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
            end # para_headers.each
        end
    end # BodyText
end


module Record::Section
    class ParaHeader
        attr_reader :chars,
                    :control_mask,
                    :para_shape_id,
                    :para_style_id,
                    :column_type,
                    :num_char_shape,
                    :num_range_tag,
                    :num_align,
                    :para_instance_id,
                    :level
        attr_accessor :para_texts,
                      :para_char_shapes,
                      :para_line_segs,
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
            @para_texts = []
            @para_char_shapes = []
            @para_line_segs = []
            @ctrl_headers = []
        end

        def hierarchy_check(level1, level2, line_num)
            if level1 != level2 - 1
                p [level1, level2, line_num]
                raise "hierarchy error at line #{line_num}"
            end
        end

        private :hierarchy_check

        def parse(parser)
            while parser.has_next?
                if parser.stack.empty?
                    parser.pull
                else
                    parser.stack.pop
                end

                case parser.tag_id
                when :HWPTAG_PARA_HEADER
                    if parser.level <= @level
                        # para header 가 끝이 나고 새롭게 시작됨을 알린다.
                        parser.stack << parser.tag_id
                        break
                    else
                        puts [@level, parser.level]
                        raise "unhandled " + parser.tag_id.to_s
                    end
                when :HWPTAG_PARA_TEXT
                    hierarchy_check(@level, parser.level, __LINE__)
                    para_text = ParaText.new(parser.data, parser.level)
                    @para_texts << para_text
                when :HWPTAG_PARA_CHAR_SHAPE
                    hierarchy_check(@level, parser.level, __LINE__)
                    para_char_shape = ParaCharShape.new(parser.data, parser.level)
                    @para_char_shapes << para_char_shape
                when :HWPTAG_PARA_LINE_SEG
                    hierarchy_check(@level, parser.level, __LINE__)
                    para_line_seg = ParaLineSeg.new(parser.data, parser.level)
                    @para_line_segs << para_line_seg
                when :HWPTAG_CTRL_HEADER
                    if parser.level <= @level
                        parser.stack << parser.tag_id
                        break
                    else
                        hierarchy_check(@level, parser.level, __LINE__)
                        ctrl_header = CtrlHeader.new(parser.data, parser.level)
                        ctrl_header.parse(parser)
                        @ctrl_headers << ctrl_header
                    end
                else
                    raise "unhandled " + parser.tag_id.to_s
                end
            end
        end

        def to_tag
            "HWPTAG_PARA_HEADER"
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

        def to_tag
            "HWPTAG_PARA_TEXT"
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

        def to_tag
            "HWPTAG_PARA_CHAR_SHAPE"
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

        def to_tag
            "HWPTAG_PARA_LINE_SEG"
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
    class CtrlHeader
        attr_reader :ctrl_id, :level
        attr_accessor :page_defs, :footnote_shapes, :page_border_fills,
                      :list_headers, :para_headers, :tables, :text_table,
                      :eq_edits
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
            @list_headers, @para_headers, @tables, @eq_edits = [], [], [], []

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

        def hierarchy_check(level1, level2, line_num)
            if level1 != level2 - 1
                p [level1, level2]
                raise "hierarchy error at line #{line_num}"
            end
        end

        def parse(parser)
            while parser.has_next?
                if parser.stack.empty?
                    parser.pull
                else
                    parser.stack.pop
                end

                case parser.tag_id
                when :HWPTAG_PAGE_DEF
                    hierarchy_check(@level, parser.level, __LINE__)
                    @page_defs << PageDef.new(parser.data, parser.level)
                when :HWPTAG_FOOTNOTE_SHAPE
                    hierarchy_check(@level, parser.level, __LINE__)
                    @footnote_shapes <<
                        FootnoteShape.new(parser.data, parser.level)
                when :HWPTAG_PAGE_BORDER_FILL
                    hierarchy_check(@level, parser.level, __LINE__)
                    @page_border_fills <<
                        PageBorderFill.new(parser.data, parser.level)
                when :HWPTAG_CTRL_HEADER
                    # CTRL_HEADER 가 끝이 나고 새롭게 시작됨을 알린다.
                    parser.stack << parser.tag_id
                    break
                when :HWPTAG_PARA_HEADER
                    if parser.level <= @level
                        parser.stack << parser.tag_id
                        break
                    else
                        #p [@level, parser.level, __LINE__]
                        hierarchy_check(@level, parser.level, __LINE__)
                        para_header = ParaHeader.new(parser.data, parser.level)
                        para_header.parse(parser)
                        @para_headers << para_header
                    end
                when :HWPTAG_LIST_HEADER
                    hierarchy_check(@level, parser.level, __LINE__)
                    @list_headers <<
                        ListHeader.new(parser.data, parser.level)
                when :HWPTAG_EQEDIT
                    hierarchy_check(@level, parser.level, __LINE__)
                    @eq_edits << EqEdit.new(parser.data, parser.level)
                else
                    raise "unhandled " + parser.tag_id.to_s
                end
            end
        end

        def to_tag
            "HWPTAG_CTRL_HEADER"
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

        def to_tag
            "HWPTAG_LIST_HEADER"
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

        def to_tag
            "HWPTAG_PAGE_DEF"
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

        def to_tag
            "HWPTAG_FOOTNOTE_SHAPE"
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

        def to_tag
            "HWPTAG_PAGE_BORDER_FILL"
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

        def to_tag
            "HWPTAG_EQEDIT"
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
