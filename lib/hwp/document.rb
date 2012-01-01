# coding: utf-8

begin
    require 'ole/storage'
rescue LoadError
    puts "If you are a debian user, " +
         "apt-get install libole-ruby or gem install ruby-ole"
    exit
rescue Exception => e
    puts e.message
    puts e.backtrace
    exit
end

require 'hwp/file_header.rb'
require 'hwp/doc_info.rb'
require 'hwp/body_text.rb'
#require 'hwp/view_text.rb'
#require 'hwp/summary_information.rb'
#require 'hwp/bin_data.rb'
#require 'hwp/prv_text.rb'
#require 'hwp/prv_image.rb'
#require 'hwp/doc_options.rb'
#require 'hwp/scripts.rb'
#require 'hwp/xml_template.rb'
#require 'hwp/doc_history.rb'
require 'hwp/model.rb'
require 'hwp/tags.rb'
require 'hwp/parser.rb'
require 'pango'

class Pango::Layout
    def size_in_points
        self.size.collect { |v| v / Pango::SCALE }
    end

    def width_in_points
        self.size[0] / Pango::SCALE
    end

    def height_in_points
        self.size[1] / Pango::SCALE
    end

    def width_in_points=(width)
        self.width = width * Pango::SCALE
    end
end


module HWP
    class Document
        attr_reader :file_header, :doc_info, :body_text, :view_text,
                    :summary_info, :bin_data, :prv_text, :prv_image,
                    :doc_options, :scripts, :xml_template, :doc_history

        def initialize filename
            @ole = Ole::Storage.open(filename, 'rb')
            remain = @ole.dir.entries('/') - ['.', '..']
            # 스펙이 명확하지 않고, 추후 스펙이 변할 수 있기 때문에
            # 이를 감지하고자 코드를 이렇게 작성하였다.
            root_entries = [ "FileHeader", "DocInfo", "BodyText", "ViewText",
                        "\005HwpSummaryInformation", "BinData", "PrvText", "PrvImage",
                        "DocOptions", "Scripts", "XMLTemplate", "DocHistory" ]

            root_entries.each do |entry|
                case @ole.file.file? entry
                when true  # file
                    file = @ole.file.open entry
                when false # dir
                    dirent = @ole.dirent_from_path entry
                when nil   # nothing
                    next
                end

                case entry
                when "FileHeader" then @file_header = FileHeader.new file
                when "DocInfo"
                    @doc_info = Record::DocInfo.new(file, @file_header)
                when "BodyText"
                    @body_text = HWP::Parser::BodyText.new(dirent, @file_header)
                when "ViewText"
                    @view_text = Record::ViewText.new(dirent, @file_header)
                when "\005HwpSummaryInformation"
                    @summary_info = HWP::Parser::SummaryInformation.new file
                when "BinData"
                    @bin_data = Record::BinData.new(dirent, @file_header)
                when "PrvText"
                    @prv_text = HWP::Parser::PrvText.new file
                when "PrvImage"
                    @prv_image = HWP::Parser::PrvImage.new file
                when "DocOptions"
                    @doc_options = HWP::Parser::DocOptions.new dirent
                when "Scripts"
                    @scripts = HWP::Parser::Scripts.new dirent
                when "XMLTemplate"
                    @xml_template = Record::XMLTemplate.new dirent
                when "DocHistory"
                    @doc_history =
                        Record::DocHistory.new(dirent, @file_header)
                else raise "unknown entry"
                end
                # 스펙에 앖는 것을 감지하기 위한 코드
                remain = remain - [entry]
            end # root_entries.each

            raise "unknown entry" unless remain.empty?
        end

        # 아래는 렌더링에 관련된 함수이다.
        def get_page n
            if @pages.nil?
                make_pages()
            end
            @pages[n]
        end

        def n_pages
            if @pages.nil?
                make_pages()
            end
            @n_pages
        end

        def make_pages
            layouts = []
            @body_text.paragraphs.each do |para|
                layouts << para.to_layout(self)
            end

            @pages = []
            @n_pages = 0

            section_def = @body_text.paragraphs[0].ctrl_headers[0].section_defs[0]
            page_def = section_def.page_defs[0]

            @y = (page_def.top_margin + page_def.header_margin) / 100.0

            layouts.each do |layout|
                @y = @y + layout.pixel_size[1]
                if @y > (page_def.height - page_def.bottom_margin - page_def.footer_margin) / 100.0
                    @n_pages += 1
                    @y = (page_def.top_margin + page_def.header_margin) / 100.0
                end
                @pages[@n_pages] ||= Page.new(page_def.width / 100.0, page_def.height / 100.0)
                @pages[@n_pages].layouts << layout
            end
        end

        def close
            @ole.close
        end
    end # Document

    class Page
        attr_accessor :layouts
        def initialize(width=nil, height=nil)
            @width, @height = width, height
            @layouts = []
        end

        def size
            [@width, @height]
        end
    end
end # HWP
