# coding: utf-8
# 한글과컴퓨터의 글 문서 파일(.hwp) 공개 문서를 참고하여 개발하였습니다.

require 'hwp/utils.rb'

# HWP Document Model
module HWP
    module Model
        class SectionDef
            attr_reader :page_defs, :footnote_shapes, :page_border_fills

            def initialize(ctrl_header)
                @level = ctrl_header.level
                @ctrl_header = ctrl_header
                @page_defs, @footnote_shapes, @page_border_fills = [], [], []
            end

            def parse(context)
                while context.has_next?
                    context.stack.empty? ? context.pull : context.stack.pop

                    if  context.level <= @level
                        context.stack << context.tag_id
                        break
                    end

                    case context.tag_id
                    when :HWPTAG_CTRL_DATA
                        # TODO
                    when :HWPTAG_PAGE_DEF
                        @page_defs << Record::Section::
                            PageDef.new(context)
                    when :HWPTAG_FOOTNOTE_SHAPE
                        @footnote_shapes << Record::Section::
                            FootnoteShape.new(context)
                    when :HWPTAG_PAGE_BORDER_FILL
                        @page_border_fills << Record::Section::
                            PageBorderFill.new(context)
                    else
                        raise "unhandled " + context.tag_id.to_s
                    end
                end # while
            end # parse
        end # SectionDef

        class ColumnDef
            def initialize(ctrl_header)
                @level = ctrl_header.level
                @ctrl_header = ctrl_header
            end
        end # ColumnDef

        class NewNum
            def initialize(ctrl_header)
                @level = ctrl_header.level
                @ctrl_header = ctrl_header
            end
        end # NewNum

        class AutoNum
            def initialize(ctrl_header)
                @level = ctrl_header.level
                @ctrl_header = ctrl_header
            end
        end # AutoNum

        class Header # 머리글
            include HWP::Utils
            def initialize(ctrl_header)
                @level = ctrl_header.level
                @ctrl_header = ctrl_header
            end

            def parse context
                while context.has_next?
                    if context.stack.empty?
                        context.pull
                    else
                        context.stack.pop
                    end

                    case context.tag_id
                    when :HWPTAG_CTRL_HEADER
                        # CTRL_HEADER 가 끝이 나고 새롭게 시작됨을 알린다.
                        context.stack << context.tag_id
                        break
                    when :HWPTAG_PARA_HEADER
                        if context.level <= @level
                            context.stack << context.tag_id
                            break
                        else
                            #p [@level, context.level, __LINE__]
                            hierarchy_check(@level, context.level, __LINE__)
                            para_header = Record::Section::
                                ParaHeader.new(context)
                            @ctrl_header.para_headers << para_header
                        end
                    when :HWPTAG_LIST_HEADER
                        hierarchy_check(@level, context.level, __LINE__)
                        @ctrl_header.list_headers << Record::Section::
                            ListHeader.new(context)
                    else
                        raise "unhandled " + context.tag_id.to_s
                    end
                end # while
            end # parse
        end # Header

        class Footer
            include HWP::Utils
            def initialize(ctrl_header)
                @level = ctrl_header.level
                @ctrl_header = ctrl_header
            end

            def parse context
                while context.has_next?
                    if context.stack.empty?
                        context.pull
                    else
                        context.stack.pop
                    end

                    case context.tag_id
                    when :HWPTAG_CTRL_HEADER
                        # CTRL_HEADER 가 끝이 나고 새롭게 시작됨을 알린다.
                        context.stack << context.tag_id
                        break
                    when :HWPTAG_PARA_HEADER
                        if context.level <= @level
                            context.stack << context.tag_id
                            break
                        else
                            #p [@level, context.level, __LINE__]
                            hierarchy_check(@level, context.level, __LINE__)
                            para_header = Record::Section::
                                ParaHeader.new(context)
                            @ctrl_header.para_headers << para_header
                        end
                    when :HWPTAG_LIST_HEADER
                        hierarchy_check(@level, context.level, __LINE__)
                        @ctrl_header.list_headers << Record::Section::
                            ListHeader.new(context)
                    else
                        raise "unhandled " + context.tag_id.to_s
                    end
                end # while
            end # parse
        end # Footer

        class TextCompose
            def initialize(ctrl_header)
                @level = ctrl_header.level
                @ctrl_header = ctrl_header
            end
        end # TextCompose

        class PageHiding
            def initialize(ctrl_header)
                @level = ctrl_header.level
                @ctrl_header = ctrl_header
            end
        end # PageHiding

        #class Table
        #    attr_accessor :page_break, :repeat_header, :row_count, :col_count,
        #                  :cell_spacing, :border_fill
        #end

        class Table
            include HWP::Utils
            #table
            #    row1
            #        cell1
            #        cell2
            #        cell3
            #    row2
            #        cell1
            #        cell2 number-rows-spanned = 2
            #        cell3
            #    row3
            #        cell1
            #        covered-table-cell
            #        cell3
            attr_accessor :rows

            def initialize(ctrl_header)
                @ctrl_header = ctrl_header
                @level = ctrl_header.level
                @rows = []
            end

            def parse context
                while context.has_next?
                    context.stack.empty? ? context.pull : context.stack.pop

                    if  context.level <= @level
                        context.stack << context.tag_id
                        break
                    end

                    # 43쪽, 표 70, 표 개체 속성, 149쪽
                    case context.tag_id
                    when :HWPTAG_TABLE
                        sio = StringIO.new context.data

                        unknown = sio.read(4)
                        row_count    = sio.read(2).unpack("v")[0]
                        col_count    = sio.read(2).unpack("v")[0]
                        cell_spacing = sio.read(2).unpack("v")[0]
                        # margin
                        left_margin  = sio.read(2).unpack("v")[0]
                        right_margin = sio.read(2).unpack("v")[0]
                        top_margin    = sio.read(2).unpack("v")[0]
                        bottom_margin  = sio.read(2).unpack("v")[0]

                        row_size = sio.read(2 * row_count).unpack("v*")
                        border_fill_id = sio.read(2).unpack("v")[0]
                        unless sio.eof?
							valid_zone_info_size = sio.read(2).unpack("v")[0]
							unless sio.eof?
								sio.close
								raise "data size mismatch"
							end
                        end
                        sio.close

                        # row 만들기
                        @rows = Array.new(row_count).collect { Table::Row.new }
                    when :HWPTAG_LIST_HEADER
                        #p context.data.to_formatted_hex
                        sio = StringIO.new context.data
                        ##
                        para_count = sio.read(2).unpack("v")[0]
                        sio.read(2).unpack("v")[0]
                        sio.read(2).unpack("v")[0]
                        sio.read(2).unpack("v")[0]
                        ##
                        col_addr = sio.read(2).unpack("v")[0]
                        row_addr = sio.read(2).unpack("v")[0]
                        col_span = sio.read(2).unpack("v")[0]
                        row_span = sio.read(2).unpack("v")[0]
                        width  = sio.read(4).unpack("V")[0]
                        height = sio.read(4).unpack("V")[0]
                        margins = sio.read(2 * 4).unpack("v*")
                        border_fill_id = sio.read(2).unpack("v")[0]
                        remain = sio.read
                        unless remain.empty?
                            puts "unknown LIST_HEADER data #{remain.to_formatted_hex}"
                        end
                        sio.close

                        # cell 만들기
                        if @ctrl_header.ctrl_id == 'tbl '
							@rows[row_addr].cells[col_addr] = Table::Cell.new
                            @rows[row_addr].cells[col_addr].width  = width
                            @rows[row_addr].cells[col_addr].height = height
                            @rows[row_addr].cells[col_addr].row_span = row_span
                            @rows[row_addr].cells[col_addr].col_span = col_span
                            
                            if col_span > 1
                                for i in col_addr...(col_addr + col_span)
									@rows[row_addr].cells[i] ||= Table::Cell.new
                                    @rows[row_addr].cells[i].covered = true
                                end
                            end
							
                            if row_span > 1
                                for i in row_addr...(row_addr + row_span)
									@rows[i].cells[col_addr] ||= Table::Cell.new
                                    @rows[i].cells[col_addr].covered = true
                                end
                            end
                        else
                            raise # FIXME
                            @list_headers << list_header  # FIXME
                        end
                    when :HWPTAG_PARA_HEADER
                        @rows[row_addr].cells[col_addr].para_headers <<
                            Record::Section::ParaHeader.new(context)
                    else
                        raise "unhandled " + context.tag_id.to_s
                    end
                end # while
            end # parse

            # TODO
            def render(cr, x, y)
                x0 = x
                @rows.each do |row|
                    row.each do |cell|
                        cr.rectangle(x, y, cell.width, cell.height)
                        cr.close_path
                        x += cell.width
                    end
                    x = x0
                    y += cell.height
                end
            end

            class Row
                attr_accessor :cells
                def initialize
                    @cells = []
                end
            end

            class Cell
                attr_accessor :para_headers, :width, :height,
                              :row_span, :col_span, :covered
                def initialize
                    @para_headers = []
                    @covered = false
                    @row_span = 1
                    @col_span = 1
                end
            end
        end # Table

        class Footnote # 각주
            include HWP::Utils

            def initialize(ctrl_header)
                @level = ctrl_header.level
                @ctrl_header = ctrl_header
            end

            def parse context
                while context.has_next?
                    if context.stack.empty?
                        context.pull
                    else
                        context.stack.pop
                    end

                    case context.tag_id
                    when :HWPTAG_CTRL_HEADER
                        # CTRL_HEADER 가 끝이 나고 새롭게 시작됨을 알린다.
                        context.stack << context.tag_id
                        break
                    when :HWPTAG_PARA_HEADER
                        if context.level <= @level
                            context.stack << context.tag_id
                            break
                        else
                            #p [@level, context.level, __LINE__]
                            hierarchy_check(@level, context.level, __LINE__)
                            para_header = Record::Section::
                                ParaHeader.new(context)
                            @ctrl_header.para_headers << para_header # FIXME
                        end
                    when :HWPTAG_LIST_HEADER
                        hierarchy_check(@level, context.level, __LINE__)
                        @ctrl_header.list_headers << Record::Section:: # FIXME
                            ListHeader.new(context)
                    else
                        raise "unhandled " + context.tag_id.to_s
                    end
                end # while
            end # parse
        end # Footnote

        class FormObject
            include HWP::Utils
            attr_reader :level
            def initialize ctrl_header
                @data  = ctrl_header.data
                @level = ctrl_header.level
            end

            def parse context
                while context.has_next?
                    if context.stack.empty?
                        context.pull
                    else
                        context.stack.pop
                    end

                    case context.tag_id
                    when :HWPTAG_CTRL_HEADER
                        # CTRL_HEADER 가 끝이 나고 새롭게 시작됨을 알린다.
                        context.stack << context.tag_id
                        break
                    when :HWPTAG_PARA_HEADER
                        if context.level <= @level
                            context.stack << context.tag_id
                            break
                        else
                            #p [@level, context.level, __LINE__]
                            hierarchy_check(@level, context.level, __LINE__)
                            para_header = ParaHeader.new(context)
                            para_header.parse(context)
                            @para_headers << para_header
                        end
                    when :HWPTAG_FORM_OBJECT
                        hierarchy_check(@level, context.level, __LINE__)
                    else
                        raise "unhandled " + context.tag_id.to_s
                    end
                end # while
            end # parse
        end # FormObject


        class EqEdit
            include HWP::Utils
            # TODO DOT 훈DOT 민 DOT 정 DOT 음
            attr_reader :level
            def initialize ctrl_header
                @data  = ctrl_header.data
                @level = ctrl_header.level
                io = StringIO.new(@data)
                property = io.read(4).unpack("I")   # INT32
                len = io.read(2).unpack("s")[0] # WORD
                #io.read(len * 2).unpack("S*").pack("U*")       # WCHAR
                @script = io.read(len * 2).unpack("v*").pack("U*")  # WCHAR
                #p unknown = io.read(2).unpack("S") # 스펙 50쪽과 다름
                #p size = io.read(4).unpack("I")        # HWPUNIT
                #p color = io.read(4).unpack("I")   # COLORREF
                #p baseline = io.read(2).unpack("s")    # INT16
            end

            def parse context
                while context.has_next?
                    if context.stack.empty?
                        context.pull
                    else
                        context.stack.pop
                    end

                    case context.tag_id
                    when :HWPTAG_CTRL_HEADER
                        # CTRL_HEADER 가 끝이 나고 새롭게 시작됨을 알린다.
                        context.stack << context.tag_id
                        break
                    when :HWPTAG_PARA_HEADER
                        if context.level <= @level
                            context.stack << context.tag_id
                            break
                        else
                            #p [@level, context.level, __LINE__]
                            hierarchy_check(@level, context.level, __LINE__)
                            para_header = ParaHeader.new(context)
                            para_header.parse(context)
                            @para_headers << para_header
                        end
                    when :HWPTAG_EQEDIT
                        hierarchy_check(@level, context.level, __LINE__)
                        #@eq_edits << EqEdit.new(context)
                    else
                        raise "unhandled " + context.tag_id.to_s
                    end
                end # while
            end # parse

            def to_tag
                "HWPTAG_EQEDIT"
            end

            def to_s
                @script
            end
        end # EqEdit

        class ShapeComponent
            include HWP::Utils
            attr_reader :scale_matrices, :rotate_matrices, :level
            FLIP_TYPE = ['horz flip', 'vert flip']

            def initialize ctrl_header
                @ctrl_header = ctrl_header
                @data  = ctrl_header.data
                @level = ctrl_header.level
                @scale_matrices, @rotate_matrices = [], []
                s_io = StringIO.new @data
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
                #center_y = s_io.read(4).unpack("V")[0]

                #count = s_io.read(2).unpack("v")[0]
                #trans_matrix = s_io.read(48).unpack("E6")

                #count.times do
                #    @scale_matrices  << s_io.read(48).unpack("E6")
                #    @rotate_matrices << s_io.read(48).unpack("E6")
                #end
            end # initialize

            def parse context
                while context.has_next?
                    if context.stack.empty?
                        context.pull
                    else
                        context.stack.pop
                    end

                    case context.tag_id
                    when :HWPTAG_CTRL_HEADER
                        # CTRL_HEADER 가 끝이 나고 새롭게 시작됨을 알린다.
                        context.stack << context.tag_id
                        break
                    when :HWPTAG_PARA_HEADER
                        if context.level <= @level
                            context.stack << context.tag_id
                            break
                        else
                            #p [@level, context.level, __LINE__]
                            # FIXME
                            #hierarchy_check(@level, context.level, __LINE__)
                            para_header = Record::Section::
                                ParaHeader.new(context)
                            @ctrl_header.para_headers << para_header # FIXME
                        end
                    when :HWPTAG_LIST_HEADER
                        # FIXME
                        #hierarchy_check(@level, context.level, __LINE__)
                    when :HWPTAG_SHAPE_COMPONENT
                        # FIXME
                        #hierarchy_check(@level, context.level, __LINE__)
                        #@level += 1
                    when :HWPTAG_SHAPE_COMPONENT_PICTURE
                        # FIXME
                        #hierarchy_check(@level, context.level, __LINE__)
                    when :HWPTAG_SHAPE_COMPONENT_RECTANGLE
                        # FIXME
                        #hierarchy_check(@level, context.level, __LINE__)
                    when :HWPTAG_SHAPE_COMPONENT_LINE
                        # FIXME
                        #hierarchy_check(@level, context.level, __LINE__)
                    when :HWPTAG_SHAPE_COMPONENT_POLYGON
                        # FIXME
                        #hierarchy_check(@level, context.level, __LINE__)
                    when :HWPTAG_SHAPE_COMPONENT_ELLIPSE
                        # FIXME
                        #hierarchy_check(@level, context.level, __LINE__)
                    else
                        raise "unhandled " + context.tag_id.to_s
                    end
                end # while
            end # parse
        end # ShapeComponent

        class ClickHere
            def initialize(ctrl_header)
                @level = ctrl_header.level
                @ctrl_header = ctrl_header
            end
        end # ClickHere
    end # Model
end # HWP
