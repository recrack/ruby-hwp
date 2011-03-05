# coding: utf-8
# apt-get install libole-ruby
# or gem install ruby-ole
# 한글과컴퓨터의 글 문서 파일(.hwp) 공개 문서를 참고하여 개발하였습니다.

require 'ole/storage'
require 'zlib'
require 'stringio'
require 'hwp/model.rb'
require 'hwp/tags.rb'
##
require 'hwp/parser.rb'

module HWP
	def self.open file
		Document.new file
	end

	class Document
		attr_reader :entries, :header, :doc_info, :bodytext, :view_text,
					:summary_info, :bin_data, :prv_text, :prv_image,
					:doc_options, :scripts, :xml_template, :doc_history

		def initialize file
			@ole = Ole::Storage.open(file, 'rb')
			_entries = @ole.dir.entries('/') - ['.', '..']

			_ROOT_ELEMENTS = [ "FileHeader", "DocInfo", "BodyText", "ViewText",
						"\005HwpSummaryInformation", "BinData", "PrvText", "PrvImage",
						"DocOptions", "Scripts", "XMLTemplate", "DocHistory" ]

			# sorting by priority
			@entries = _ROOT_ELEMENTS - (_ROOT_ELEMENTS - _entries)

			@entries.each do |entry|
				if @ole.file.file? entry
					file = @ole.file.open entry
				else
					dirent = @ole.dirent_from_path entry
				end

				case entry
				when "FileHeader"	then @header = FileHeader.new file
				when "DocInfo"		then @doc_info = Record::DocInfo.new(file, @header)
				when "BodyText"		then @bodytext = Record::BodyText.new(dirent, @header)
				when "ViewText"		then @view_text = Record::ViewText.new dirent
				when "\005HwpSummaryInformation"
					@summary_info = Record::SummaryInformation.new file
				when "BinData"		then @bin_data = Record::BinData.new(dirent, @header)
				when "PrvText"		then @prv_text = Record::PrvText.new file
				when "PrvImage"		then @prv_image = Record::PrvImage.new file
				when "DocOptions"	then @doc_options = Record::DocOptions.new dirent
				when "Scripts"		then @scripts = Record::Scripts.new dirent
				when "XMLTemplate"	then @xml_template = Record::XMLTemplate.new dirent
				when "DocHistory"	then @doc_history = Record::DocHistory.new(dirent, @header)
				else raise "unknown entry"
				end
			end
		end

		def close
			@ole.close
		end
	end

	class FileHeader
		attr_reader :signature, :version
		def initialize file
			@signature	= file.read 32
			@version	= file.read(4).reverse.unpack("C*").join(".")
			@property	= file.read(4).unpack("V").pop
			@reversed	= file.read 216
		end

		def compress?;				(@property & (1 <<  0)).zero? ? false : true;	end
		def encrypt?;				(@property & (1 <<  1)).zero? ? false : true;	end
		def distribute?;			(@property & (1 <<  2)).zero? ? false : true;	end
		def script?;				(@property & (1 <<  3)).zero? ? false : true;	end
		def drm?;					(@property & (1 <<  4)).zero? ? false : true;	end
		def xml_template?;			(@property & (1 <<  5)).zero? ? false : true;	end
		def history?;				(@property & (1 <<  6)).zero? ? false : true;	end
		def sign?;					(@property & (1 <<  7)).zero? ? false : true;	end
		def certificate_encrypt?;	(@property & (1 <<  8)).zero? ? false : true;	end
		def sign_spare?;			(@property & (1 <<  9)).zero? ? false : true;	end
		def certificate_drm?;		(@property & (1 << 10)).zero? ? false : true;	end
		def ccl?;					(@property & (1 << 11)).zero? ? false : true;	end
	end
end
