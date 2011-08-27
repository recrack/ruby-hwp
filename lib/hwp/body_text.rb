require 'hwp/utils'

module Record
    class BodyText
        attr_accessor :para_headers

        def initialize(dirent, header)
            @para_headers = []

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
                    @para_headers << Record::Section::ParaHeader.new(context)
                else
                    raise "unhandled: #{context.tag_id}"
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
        include HWP::Utils

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
                      :table

        def initialize context
            @level = context.level
            @chars,
            @control_mask,
            @para_shape_id,
            @para_style_id,
            @column_type,
            @num_char_shape,
            @num_range_tag,
            @num_align,
            @para_instance_id = context.data.unpack("vVvvvvvvV")

            # para_text, para_char_shape 가 1개 밖에 안 오는 것 같으나 확실하지 않으니
            # 배열로 처리한다. 추후 ParaText, ParaCharShape 클래스를 ParaHeader 이나
            # 이와 유사한 자료구조(예를 들면, Paragraph)에 내포하는 것을 고려한다.
            # para_header 에는 para_text 가 1개만 오는 것 같다.
            @para_texts = []
            @para_char_shapes = []
            @para_line_segs = []
            @ctrl_headers = []
            parse(context)
        end

        def parse(context)
            while context.has_next?
                context.stack.empty? ? context.pull : context.stack.pop

                if  context.level <= @level
                    context.stack << context.tag_id
                    break
                end

                case context.tag_id
                when :HWPTAG_PARA_TEXT
                    @para_texts << ParaText.new(context)
                when :HWPTAG_PARA_CHAR_SHAPE
                    @para_char_shapes << ParaCharShape.new(context)
                when :HWPTAG_PARA_LINE_SEG
                    @para_line_segs << ParaLineSeg.new(context)
                when :HWPTAG_CTRL_HEADER
                    @ctrl_headers << CtrlHeader.new(context)
                #when :HWPTAG_MEMO_LIST
                #    # TODO
                # table, memo_list 에서 HWPTAG_LIST_HEADER 가 온다.
                #when :HWPTAG_LIST_HEADER
                #    if context.level <= @level
                #        context.stack << context.tag_id
                #        break
                #    else
                #        #raise "unhandled " + context.tag_id.to_s
                #    end
                # HWPTAG_SHAPE_COMPONENT
                #  HWPTAG_LIST_HEADER
                #  HWPTAG_PARA_HEADER
                #   HWPTAG_PARA_TEXT
                #   HWPTAG_PARA_CHAR_SHAPE
                #   HWPTAG_PARA_LINE_SEG
                #  HWPTAG_SHAPE_COMPONENT_RECTANGLE
                #when :HWPTAG_SHAPE_COMPONENT_RECTANGLE
                #    if context.level <= @level
                #        context.stack << context.tag_id
                #        break
                #    else
                #        raise "unhandled " + context.tag_id.to_s
                #    end
                else
                    raise "unhandled " + context.tag_id.to_s
                end
            end
        end
        private :parse

        def to_tag
            "HWPTAG_PARA_HEADER"
        end

        def debug
            puts "\t"*@level + "ParaHeader:"
        end
    end

    class ParaText
        attr_reader :level

        def initialize context
            @level = context.level
            s_io = StringIO.new context.data

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
                # 포인터가 있다고 하는데 살펴보니 tbl의 경우 포인터가 없고
                # ctrl id 만 있다.
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
        def initialize context
            data = context.data
            @level = context.level
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
    # 스펙 문서에는 생략한다고 나와 있다. hwp3.0 또는 hwpml 스펙에 관련 정보가
    # 있는지 확인해야 한다.
    class ParaLineSeg
        attr_reader :level

        def initialize context
            @level = context.level
            @data  = context.data
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
        def initialize context
            @level = context.level
            raise NotImplementedError.new "Record::Section::ParaRangeTag"
            #@start, @end, @tag = data.unpack("VVb*")
        end
    end

    # TODO REVERSE-ENGINEERING
    class CtrlHeader
        include HWP::Utils

        attr_reader :ctrl_id, :level, :data
        attr_accessor :section_defs, :list_headers, :para_headers, :tables,
                      :text_table,   :eq_edits

        def initialize context
            @data = context.data
            @level = context.level
            s_io = StringIO.new context.data
            @ctrl_id = s_io.read(4).reverse

            puts(" " * level + "\"#{@ctrl_id}\"")

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

            @section_defs, @list_headers, @para_headers = [], [], []
            @tables, @eq_edits = [], []

            parse(context)
        end

        def parse(context)
            # ctrl id 에 따른 모델링과 그외 처리
            case @ctrl_id
            # 54쪽 표116 그외 컨트롤
            when "secd" # 구역 정의
                # TODO SectionDef 위치: 현재는 ctrl_header 에 위치하는데
                # 적절한 곳에 위치시킬 필요가 있다.
                secd = HWP::Model::SectionDef.new(self)
                secd.parse(context)
                @section_defs << secd
            when "cold" # 단 정의
                cold = HWP::Model::ColumnDef.new(self)
            when "head" # 머리말 header
                head = HWP::Model::Header.new(self)
                head.parse(context)
            when "foot" # 꼬리말 footer
                foot = HWP::Model::Footer.new(self)
                foot.parse(context)
            when "fn  " # 각주
                footnote = HWP::Model::Footnote.new(self)
                footnote.parse(context)
            when "en  " then raise NotImplementedError.new @ctrl_id
            when "atno" # 자동 번호
                atno = HWP::Model::AutoNum.new(self)
                return
            when "nwno" # 새 번호 지정
                nwno = HWP::Model::NewNum.new(self)
                return
            when "pghd" # 감추기 page hiding
                pghd = HWP::Model::PageHiding.new(self)
                return
            when "pgct" then raise NotImplementedError.new @ctrl_id
            when "pgnp" then raise NotImplementedError.new @ctrl_id
            when "idxm" then raise NotImplementedError.new @ctrl_id
            when "bokm" then raise NotImplementedError.new @ctrl_id
            when "tcps" # 글자 겹침 text compose 170쪽
                tcps = HWP::Model::TextCompose.new(self)
                return
            when "tdut" then raise NotImplementedError.new @ctrl_id
            when "tcmt" then raise NotImplementedError.new @ctrl_id
            # 41쪽 표62 개체 공통 속성을 포함하는 컨트롤
            when 'tbl '
                table = HWP::Model::Table.new(self)
                table.parse(context)
            when 'gso '
                gso = HWP::Model::ShapeComponent.new(self)
                gso.parse(context)
            when 'form'
                form = HWP::Model::FormObject.new(self)
                form.parse context
            when '$lin' then raise NotImplementedError.new @ctrl_id
            when '$rec' then raise NotImplementedError.new @ctrl_id
            when '$ell' then raise NotImplementedError.new @ctrl_id
            when '$arc' then raise NotImplementedError.new @ctrl_id
            when '$pol' then raise NotImplementedError.new @ctrl_id
            when '$cur' then raise NotImplementedError.new @ctrl_id
            when 'eqed'
                eqed = HWP::Model::EqEdit.new(self)
                # 자식은 없으나 EQEDIT 레코드를 가지고 와야 한다.
                eqed.parse context
            when '$pic' then raise NotImplementedError.new @ctrl_id
            when '$ole' then raise NotImplementedError.new @ctrl_id
            when '$con' then raise NotImplementedError.new @ctrl_id
            # 54쪽 표116 필드 시작 컨트롤
            when "%unk" # FIELD_UNKNOWN
                # TODO
            when "%dte" then raise NotImplementedError.new @ctrl_id
            when "%ddt" then raise NotImplementedError.new @ctrl_id
            when "%pat" then raise NotImplementedError.new @ctrl_id
            when "%bmk" then raise NotImplementedError.new @ctrl_id
            when "%mmg" then raise NotImplementedError.new @ctrl_id
            when "%xrf" then raise NotImplementedError.new @ctrl_id
            when "%fmu" then raise NotImplementedError.new @ctrl_id
            when "%clk" # FIELD_CLICKHERE
                clk = HWP::Model::ClickHere.new(self)
                # 자식은 없으나 EQEDIT 레코드를 가지고 와야 한다.
                #eqed.parse context
            when "%smr" then raise NotImplementedError.new @ctrl_id
            when "%usr" then raise NotImplementedError.new @ctrl_id
            when "%hlk" then raise NotImplementedError.new @ctrl_id
            when "%sig" then raise NotImplementedError.new @ctrl_id
            when "%%*d" then raise NotImplementedError.new @ctrl_id
            when "%%*a" then raise NotImplementedError.new @ctrl_id
            when "%%*C" then raise NotImplementedError.new @ctrl_id
            when "%%*S" then raise NotImplementedError.new @ctrl_id
            when "%%*T" then raise NotImplementedError.new @ctrl_id
            when "%%*P" then raise NotImplementedError.new @ctrl_id
            when "%%*L" then raise NotImplementedError.new @ctrl_id
            when "%%*c" then raise NotImplementedError.new @ctrl_id
            when "%%*h" then raise NotImplementedError.new @ctrl_id
            when "%%*A" then raise NotImplementedError.new @ctrl_id
            when "%%*i" then raise NotImplementedError.new @ctrl_id
            when "%%*t" then raise NotImplementedError.new @ctrl_id
            when "%%*r" then raise NotImplementedError.new @ctrl_id
            when "%%*l" then raise NotImplementedError.new @ctrl_id
            when "%%*n" then raise NotImplementedError.new @ctrl_id
            when "%%*e" then raise NotImplementedError.new @ctrl_id
            when "%spl" then raise NotImplementedError.new @ctrl_id
            when "%%mr" then raise NotImplementedError.new @ctrl_id
            when "%%me" then raise NotImplementedError.new @ctrl_id
            when "%cpr" then raise NotImplementedError.new @ctrl_id
            else
                raise "unhandled #{@ctrl_id}"
            end

            # 다음 레코드 처리
            while context.has_next?
                context.stack.empty? ? context.pull : context.stack.pop

                if  context.level <= @level
                    context.stack << context.tag_id
                    break
                end

                case context.tag_id
                when :TODO
                else
                    raise "unhandled " + context.tag_id.to_s
                end
            end # while
        end # parse

        private :parse

        def to_tag
            "HWPTAG_CTRL_HEADER"
        end

        def debug
            puts "\t"*@level +"CtrlHeader:" + @ctrl_id
        end
    end # CtrlHeader

    # TODO REVERSE-ENGINEERING
    # 리스트 헤더: Table 다음에 올 경우 셀 속성
    class ListHeader
        attr_reader :level, :num_para,
                    # table cell
                    :col_addr, :row_addr, :col_span, :row_span,
                    :width, :height, :margins
        def initialize context
            @level = context.level
            s_io = StringIO.new context.data
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
        def initialize context
            @level = context.level
            STDERR.puts "{#self.class.name}: not implemented"
        end
    end

    # TODO REVERSE-ENGINEERING
    class Table
        attr_reader :level, :prop, :row_count, :col_count, :cell_spacing, :margins, :row_size, :border_fill_id
        def initialize context
            @level = context.level
            s_io = StringIO.new context.data
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

    class ShapeComponentLine
        attr_reader :level
        def initialize context
            @level = context.level
            STDERR.puts "{#self.class.name}: not implemented"
        end
    end

    class ShapeComponentRectangle
        attr_reader :level
        def initialize context
            @level = context.level
            STDERR.puts "{#self.class.name}: not implemented"
        end
    end

    class ShapeComponentEllipse
        attr_reader :level
        def initialize context
            @level = context.level
            STDERR.puts "{#self.class.name}: not implemented"
        end
    end

    class ShapeComponentArc
        attr_reader :level
        def initialize context
            @level = context.level
            STDERR.puts "{#self.class.name}: not implemented"
        end
    end

    class ShapeComponentPolygon
        attr_reader :level
        def initialize context
            @level = context.level
            STDERR.puts "{#self.class.name}: not implemented"
        end
    end

    class ShapeComponentCurve
        attr_reader :level
        def initialize context
            @level = context.level
            STDERR.puts "{#self.class.name}: not implemented"
        end
    end

    class ShapeComponentOLE
        attr_reader :level
        def initialize context
            @level = context.level
            STDERR.puts "{#self.class.name}: not implemented"
        end
    end

    # TODO REVERSE-ENGINEERING
    class ShapeComponentPicture
        attr_reader :level
        def initialize context
            @level = context.level
            data.unpack("V6sv4Vv vV vVvV")
        end
    end

    class ShapeComponentContainer
        attr_reader :level
        def initialize context
            @level = context.level
            STDERR.puts "{#self.class.name}: not implemented"
        end
    end

    class ShapeComponentTextArt
        attr_reader :level
        def initialize context
            @level = context.level
            STDERR.puts "{#self.class.name}: not implemented"
        end
    end

    class ShapeComponentUnknown
        attr_reader :level
        def initialize context
            @level = context.level
            STDERR.puts "{#self.class.name}: not implemented"
        end
    end

    class PageDef
        attr_reader :level, :width, :height, :left_margin, :right_margin,
                    :top_margin, :bottom_margin, :header_margin,
                    :footer_margin, :gutter_margin
        def initialize context
            @level = context.level

            @width,         @height,
            @left_margin,   @right_margin,
            @top_margin,    @bottom_margin,
            @header_margin, @footer_margin,
            @gutter_margin, @property = context.data.unpack("V*")
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
        def initialize context
            @level = context.level
            @data = context.data
            s_io = StringIO.new context.data
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
        def initialize context
            @level = context.level
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

    class Reserved
        attr_reader :level
        def initialize context
            @level = context.level
            STDERR.puts "{#self.class.name}: not implemented"
        end
    end

    class MemoShape
        attr_reader :level
        def initialize context
            @level = context.level
            STDERR.puts "{#self.class.name}: not implemented"
        end
    end

    class MemoList
        attr_reader :level
        def initialize context
            @level = context.level
            STDERR.puts "{#self.class.name}: not implemented"
        end
    end

    class ChartData
        attr_reader :level
        def initialize context
            @level = context.level
            STDERR.puts "{#self.class.name}: not implemented"
        end
    end
end # Record::Section
