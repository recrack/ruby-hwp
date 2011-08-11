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

module HWP
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
                    @summary_info = Record::SummaryInformation.new file
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

            raise "unknown entry" unless remain.empty?
        end

        def close
            @ole.close
        end
    end # Document
end # HWP
