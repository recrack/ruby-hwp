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
        def initialize(dirent, header)
        end
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

    class DocOptions
    end

    class Scripts;end

    class XMLTemplate
    end

    class DocHistory
        def initialize(dirent, header)
        end
    end
end # Record

require 'hwp/utils.rb'

# HWP Document Model
module HWP
    module Model
        class Paragraph
            attr_accessor :text
        end

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

        class Table
            include HWP::Utils
            #table
            #    column
            #    column
            #    column
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
            attr_accessor :columns, :rows

            def initialize(ctrl_header)
                @ctrl_header = ctrl_header
                #@tables = [ {:list_header1 => para_headers1},
                #            {:list_header2 => para_headers2},
                #            ...
                #          ]
                @level = ctrl_header.level
                @para_headers = []
                @columns = []
                @rows = []
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
                    when :HWPTAG_LIST_HEADER
                        # TODO
                        hierarchy_check(@level, context.level, __LINE__)
                    when :HWPTAG_PARA_HEADER
                        if context.level <= @level
                            context.stack << context.tag_id
                            break
                        else
                            #p [@level, context.level, __LINE__]
                            hierarchy_check(@level, context.level, __LINE__)
                            para_header = Record::Section::
                                ParaHeader.new(context)
                            @para_headers << para_header # FIXME
                        end
                    when :HWPTAG_TABLE
                        #hierarchy_check(@level, context.level, __LINE__)
                    else
                        raise "unhandled " + context.tag_id.to_s
                    end
                end # while
            end # parses

            # @text_table은 임시로 만든 이름이다. 더 나은 API 설계를 할 것.
            def append_table table
                @tables << table
                @text_table.rows = Array.new(table.row_count).collect do
                    Text::Table::Row.new
                end
                
                @text_table.rows.each do |row|
                    row.cells = Array.new(table.col_count).collect do
                        Text::Table::Cell.new
                    end
                end
            end

            def append_list_header list_header
                if @ctrl_id == 'tbl '
                    @col_addr = list_header.col_addr
                    @row_addr = list_header.row_addr
                    col_span = list_header.col_span
                    row_span = list_header.row_span
                    @text_table.rows[@row_addr].cells[@col_addr] =
                        Text::Table::Cell.new
                    @text_table.rows[@row_addr].cells[@col_addr].row_span =
                        row_span
                    @text_table.rows[@row_addr].cells[@col_addr].col_span =
                        col_span
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
                    # list_header 다음에 오는 연속된 para_header 에 대하여
                    # 올바르게 처리해야 한다.
                    @text_table.rows[@row_addr].cells[@col_addr].
                        para_headers << para_header
                else
                    @para_headers << para_header
                end
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
                property = io.read(4).unpack("I")	# INT32
                len = io.read(2).unpack("s")[0]	# WORD
                #io.read(len * 2).unpack("S*").pack("U*")		# WCHAR
                @script = io.read(len * 2).unpack("v*").pack("U*")	# WCHAR
                #p unknown = io.read(2).unpack("S")	# 스펙 50쪽과 다름
                #p size = io.read(4).unpack("I")		# HWPUNIT
                #p color = io.read(4).unpack("I")	# COLORREF
                #p baseline = io.read(2).unpack("s")	# INT16
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
