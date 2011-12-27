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
    # FIXME 여러 파일을 열 경우에 대한 처리 필요함.
    def self.current_document
        @current_document
    end

    def self.current_document=(doc)
        @current_document = doc
    end

    class Document
        attr_reader :header, :doc_info, :body_text, :view_text,
                    :summary_info, :bin_data, :prv_text, :prv_image,
                    :doc_options, :scripts, :xml_template, :doc_history

        def initialize filename
            @ole = Ole::Storage.open(filename, 'rb')
            remain = @ole.dir.entries('/') - ['.', '..']

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
                when "FileHeader" then @header = FileHeader.new file
                when "DocInfo"
                    @doc_info = Record::DocInfo.new(file, @header)
                when "BodyText"
                    @body_text = Record::BodyText.new(dirent, @header)
                when "ViewText"
                    @view_text = Record::ViewText.new(dirent, @header)
                when "\005HwpSummaryInformation"
                    @summary_info = Record::SummaryInformation.new
                when "BinData"
                    @bin_data = Record::BinData.new(dirent, @header)
                when "PrvText"
                    @prv_text = Record::PrvText.new file
                when "PrvImage"
                    @prv_image = Record::PrvImage.new file
                when "DocOptions"
                    @doc_options = Record::DocOptions.new dirent
                when "Scripts"
                    @scripts = Record::Scripts.new dirent
                when "XMLTemplate"
                    @xml_template = Record::XMLTemplate.new dirent
                when "DocHistory"
                    @doc_history =
                        Record::DocHistory.new(dirent, @header)
                else raise "unknown entry"
                end
                remain = remain - [entry]
            end # root_entries.each

            HWP.current_document = self

            raise "unknown entry" unless remain.empty?
        end

        def get_pages n
            @page_layouts[n]
        end

        def n_pages
            @n_pages
        end

        def make_page
            layouts = []
            @body_text.para_headers.each do |para|
                layouts << para.to_layout(self)
            end

            @page_layouts = []
            @n_pages = 0

            section_def = @body_text.para_headers[0].ctrl_headers[0].section_defs[0]
            page_def = section_def.page_defs[0]

            @y = (page_def.top_margin + page_def.header_margin) / 100.0

            layouts.each do |layout|
                @y = @y + layout.pixel_size[1]
                if @y > (page_def.height - page_def.bottom_margin - page_def.footer_margin) / 100.0
                    @n_pages += 1
                    @y = (page_def.top_margin + page_def.header_margin) / 100.0
                end
                @page_layouts[@n_pages] ||= []
                @page_layouts[@n_pages] << layout
            end
        end

        def close
            @ole.close
        end
    end # Document
end # HWP
