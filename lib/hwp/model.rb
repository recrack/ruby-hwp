# coding: utf-8
# 한글과컴퓨터의 글 문서 파일(.hwp) 공개 문서를 참고하여 개발하였습니다.

require 'stringio'
require 'hwp/datatype'

# TODO close StringIO instances
# TODO hwp2html, hwpview 등을 실행하면 parser.rb, model.rb 를 통하여 최종적으로
# 2번 정도 루프문을 도는데 1번만 돌도록 하여 성능을 향상시켜야 한다.
# .each, yield 를 parser.rb, model.rb 와 연관시키는 것을 고려한다.
# TODO BodyText, Modeller 를 알기 쉽게 개량해야 한다.

module Record
	module Header
		def self.decode bytes
			lsb_first = bytes.unpack("b*")[0] # 이진수, LSB first, bit 0 가 맨 앞에 온다.

			if lsb_first
				@tag_id	= lsb_first[0..9].reverse.to_i(2) # 9~0
				@level	= lsb_first[10..19].reverse.to_i(2) # 19~10
				@size	= lsb_first[20..31].reverse.to_i(2) # 31~20
			end
		end

		def self.tag_id;	@tag_id;	end
		def self.level;		@level;		end
		def self.size;		@size;		end
	end

	class DocInfo
		attr_reader :document_properties,
					:id_mappings,
					:bin_data,
					:face_names,
					:border_fill,
					:char_shapes,
					:tab_def,
					:numbering,
					:bullet,
					:para_shape,
					:style,
					:doc_data,
					:distribute_doc_data,
					:reserved,
					:compatible_document,
					:layout_compatibility,
					:forbidden_char

		def initialize(dirent, header)
			if header.compress?
				z = Zlib::Inflate.new(-Zlib::MAX_WBITS)
				@doc_info = StringIO.new(z.inflate dirent.read)
				z.finish; z.close
			else
				@doc_info = StringIO.new(dirent.read)
			end

			@document_properties	= []
			@id_mappings			= []
			@bin_data				= []
			@face_names				= []
			@border_fill			= []
			@char_shapes			= []
			@tab_def				= []
			@numbering				= []
			@bullet					= []
			@para_shape				= []
			@style					= []
			@doc_data				= []
			@distribute_doc_data	= []
			@reserved				= []
			@compatible_document	= []
			@layout_compatibility	= []
			@forbidden_char			= []

			parser = HWP::Parser.new @doc_info
			while parser.has_next?
				response = parser.pull
				case response
				when Record::DocInfo::DocumentProperties
					@document_properties << response
				when Record::DocInfo::IDMappings
					@id_mappings << response
				when Record::DocInfo::BinData
					@bin_data << response
				when Record::DocInfo::FaceName
					@face_names << response
				when Record::DocInfo::BorderFill
					@border_fill << response
				when Record::DocInfo::CharShape
					@char_shapes << response
				when Record::DocInfo::TabDef
					@tab_def << response
				when Record::DocInfo::Numbering
					@numbering << response
				when Record::DocInfo::Bullet
					@bullet << response
				when Record::DocInfo::ParaShape
					@para_shape << response
				when Record::DocInfo::Style
					@style << response
				when Record::DocInfo::DocData
					@doc_data << response
				when Record::DocInfo::DistributeDocData
					@distribute_doc_data << response
				when Record::DocInfo::Reserved
					@reserved << response
				when Record::DocInfo::CompatibleDocument
					@compatible_document << response
				when Record::DocInfo::LayoutCompatibility
					@layout_compatibility << response
				when Record::DocInfo::ForbiddenChar
					@forbidden_char << response
				else
					raise "UNKNOWN RECORD"
				end
			end # while
		end # initialize
	end # DocInfo

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

	class ViewText
		def initialize dirent
			raise NotImplementedError.new("ViewText is not supported")
		end
	end

	class SummaryInformation
	end

	class BinData
		def initialize(dirent, header);end
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

	class DocOptions;end
	class Scripts;end
	class XMLTemplate;end

	class DocHistory
		def initialize(dirent, header);end
	end
end # of (module Record)

module Record
#     V    | Fixnum  | treat four characters as an unsigned
#          |         | long in little-endian byte order
#   -------+---------+-----------------------------------------
#     v    | Fixnum  | treat two characters as an unsigned
#          |         | short in little-endian byte order
	class DocInfo::DocumentProperties
		attr_reader :section_count,
					# begin num
					:page_start_num,
					:footnote_start_num,
					:endnote_start_num,
					:picture_start_num,
					:table_start_num,
					:equation_start_num,
					# caret pos
					:caret_pos_list_id,
					:caret_pos_para_id,
					:caret_pos_char_pos,
					:level

		def initialize data, level
			@level = level
			@section_count,
			# begin num
			@page_start_num,
			@footnote_start_num,
			@endnote_start_num,
			@picture_start_num,
			@table_start_num,
			@equation_start_num,
			# caret pos
			@caret_pos_list_id,
			@caret_pos_para_id,
			@caret_pos_char_pos = data.unpack("v7V*")
		end
	end

	class DocInfo::IDMappings # count
		attr_reader :bin_data_count,
					# font count
					:korean_font_count,
					:english_font_count,
					:hanja_font_count,
					:japanese_font_count,
					:others_font_count,
					:symbol_font_count,
					:user_font_count,

					:border_fill_count,
					:char_shape_count,
					:tab_def_count,
					:para_numbering_count,
					:bullet_count,
					:para_shape_count,
					:style_count,
					:memo_shape_count,
					:level

		def initialize data, level
			@level = level
			@bin_data_count,
			# font count
			@korean_font_count,
			@english_font_count,
			@hanja_font_count,
			@japanese_font_count,
			@others_font_count,
			@symbol_font_count,
			@user_font_count,

			@border_fill_count,
			@char_shape_count,
			@tab_def_count,
			@para_numbering_count,
			@bullet_count,
			@para_shape_count,
			@style_count,
			@memo_shape_count = data.unpack("V*")
		end
	end

	class DocInfo::BinData
		attr_reader :type,
					:abs_path,
					:rel_path,
					:id,
					:format,
					:compress_policy,	# deprecated method
					:status,			# deprecated method
					:level

		def initialize data, level
			@level = level
			s_io = StringIO.new data
			flag = s_io.read(2).unpack("v")[0]
			# bit 0 ~ 3
			case flag & 0b0011
			when 0b0000
				@type = 'link'
				len = s_io.read(2).unpack("v")[0]
				@abs_path = s_io.read(len*2).unpack("v*").pack("U*")
				len = s_io.read(2).unpack("v")[0]
				@rel_path = s_io.read(len*2).unpack("v*").pack("U*")
			when 0b0001
				@type = 'embedding'
				@id, len = s_io.read(4).unpack("vv")
				@format = s_io.read(len*2).unpack("v*").pack("U*")
			when 0b0010
				@type = 'storage'
				@id, len = s_io.read(4).unpack("vv")
				@format = s_io.read(len*2).unpack("v*").pack("U*")
			when 0b0011
				raise "UNKNOWN TYPE"
			end
			s_io.close
			# bit 4 ~ 5
			case flag & 0b11_0000
			when 0b00_0000	then @compress_policy = 'default'
			when 0b01_0000	then @compress_policy = 'force_compress'
			when 0b10_0000	then @compress_policy = 'force_plain'
			when 0b11_0000	then raise "UNKNOWN GZIP POLICY"
			end
			# bit 6 ~ 7
			case flag & 0b1100_0000
			when 0b0000_0000 then @status = 'not yet accessed'
			when 0b0100_0000 then @status = 'access success and file found'
			when 0b1000_0000 then @status = 'access fail and error'
			when 0b1100_0000 then @status = 'access fail and ignore'
			end
		end
	end

	class DocInfo::FaceName
		attr_reader :font_name, # done
					:subst_font_type, # done
					:subst_font_name, # done
					:rep_font_name, # done
					:font_type_info,
					:level

		class TypeInfo
			# PANOSE v1.0
			# http://www.monotypeimaging.com/ProductsServices/pan2.aspx
			attr_reader :family,
						:serif_style,
						:weight,
						:proportion,
						:contrast,
						:stroke_variation,
						:arm_style,
						:letter_form,
						:midline,
						:x_height

			Family = [
				'Any',
				'No Fit',
				'Latin Text',
				'Latin Hand Written',
				'Latin Decorative',
				'Latin Symbol'
			]

			Serif_Style = [
				'Any',
				'No Fit',
				'Cove',
				'Obtuse Cove',
				'Square Cove',
				'Obtuse Square Cove',
				'Square',
				'Thin',
				'Oval',
				'Exaggerated',
				'Triangle',
				'Normal Sans',
				'Obtuse Sans',
				'Perpendicular Sans',
				'Flared',
				'Rounded'
			]

			Weight = [
				'Any',
				'No Fit',
				'Very Light',
				'Light',
				'Thin',
				'Book',
				'Medium',
				'Demi',
				'Bold',
				'Heavy',
				'Black',
				'Extra Black'
			]

			Proportion = [
				'Any',
				'No fit',
				'Old Style',
				'Modern',
				'Even Width',
				'Extended',
				'Condensed',
				'Very Extended',
				'Very Condensed',
				'Monospaced'
			]

			Contrast = [
				'Any',
				'No Fit',
				'None',
				'Very Low',
				'Low',
				'Medium Low',
				'Medium',
				'Medium High',
				'High',
				'Very High'
			]

			Stroke_Variation = [
				'Any',
				'No Fit',
				'No Variation',
				'Gradual/Diagonal',
				'Gradual/Transitional',
				'Gradual/Vertical',
				'Gradual/Horizontal',
				'Rapid/Vertical',
				'Rapid/Horizontal',
				'Instant/Vertical',
				'Instant/Horizontal'
			]

			Arm_Style = [
				'Any',
				'No Fit',
				'Straight Arms/Horizontal',
				'Straight Arms/Wedge',
				'Straight Arms/Vertical',
				'Straight Arms/Single Serif',
				'Straight Arms/Double Serif',
				'Non-Straight/Horizontal',
				'Non-Straight/Wedge',
				'Non-Straight/Vertical',
				'Non-Straight/Single Serif',
				'Non-Straight/Double Serif'
			]

			Letter_Form = [
				'Any',
				'No Fit',
				'Normal/Contact',
				'Normal/Weighted',
				'Normal/Boxed',
				'Normal/Flattened',
				'Normal/Rounded',
				'Normal/Off Center',
				'Normal/Square',
				'Oblique/Contact',
				'Oblique/Weighted',
				'Oblique/Boxed',
				'Oblique/Flattened',
				'Oblique/Rounded',
				'Oblique/Off Center',
				'Oblique/Square'
			]

			Midline = [
				'Any',
				'No Fit',
				'Standard/Trimmed',
				'Standard/Pointed',
				'Standard/Serifed',
				'High/Trimmed',
				'High/Pointed',
				'High/Serifed',
				'Constant/Trimmed',
				'Constant/Pointed',
				'Constant/Serifed',
				'Low/Trimmed',
				'Low/Pointed',
				'Low/Serifed'
			]

			X_Height = [
				'Any',
				'No Fit',
				'Constant/Small',
				'Constant/Standard',
				'Constant/Large',
				'Ducking/Small',
				'Ducking/Standard',
				'Ducking/Large'
			]

			def initialize panose
				@family				= Family[panose[0]]
				@serif_style		= Serif_Style[panose[1]]
				@weight				= Weight[panose[2]]
				@proportion			= Proportion[panose[3]]
				@contrast			= Contrast[panose[4]]
				@stroke_variation	= Stroke_Variation[panose[5]]
				@arm_style			= Arm_Style[panose[6]]
				@letter_form		= Letter_Form[panose[7]]
				@midline			= Midline[panose[8]]
				@x_height			= X_Height[panose[9]]
			end
		end # class TypeInfo

		def initialize data, level
			@level = level
			s_io = StringIO.new data
			@flag, len = s_io.read(3).unpack("Cv")
			@font_name = s_io.read(len*2).unpack("v*").pack("U*")

			if exist_subst_font?
				case s_io.read(1).unpack("C")[0]
				when 0	then @subst_font_type = 'unknown' # rep ?
				when 1	then @subst_font_type = 'ttf'
				when 2	then @subst_font_type = 'hft'
				else
					raise "UNKNOWN SUBST_FONT_TYPE"
				end
				len = s_io.read(2).unpack("v")[0]
				@subst_font_name = s_io.read(len * 2).unpack("v*").pack("U*")
			end

			if exist_font_type_info?
				panose = s_io.read(10).unpack("C*")
				@font_type_info = TypeInfo.new panose
			end

			if exist_rep_font?
				len = s_io.read(2).unpack("v")[0]
				@rep_font_name = s_io.read(len * 2).unpack("v*").pack("U*")
			end
		end # def initialize

		def exist_subst_font?
			not (@flag & 0x80).zero?
		end

		def exist_font_type_info?
			not (@flag & 0x40).zero?
		end

		def exist_rep_font?
			not (@flag & 0x20).zero?
		end
	end # class DocInfo::FaceName

	# TODO TEST
	class DocInfo::BorderFill
		attr_reader :slash,
					:backslash,
					:left_border,
					:right_border,
					:top_border,
					:bottom_border,
					:diagonal,
					:type,
					:size,
					:window_brush,
					:gradation,
					:image_brush,
					:level

		class Border
			attr_reader :type, :width, :color
			def initialize type, width, color
				@type  = type
				@width = width
				@color = color
			end
		end

		class LeftBorder < Border;end
		class RightBorder < Border;end
		class TopBorder < Border;end
		class BottomBorder < Border;end
		class Diagonal
			attr_accessor :type, :width, :color
			def initialize type, width, color
				@type  = type
				@width = width
				@color = color
			end
		end

		SLASH_TYPE = {
			'000' => 'none',
			'010' => 'break cell separate line',
			'011' => 'counter backslash',
			'110' => 'counter slash',
			'111' => 'crooked slash'
		}

		BORDER_LINE_TYPE = [
			'solid line',
			'dotted line',
			'-.-.-.-.',
			'-..-..-..',
			'long dash',
			'big dot',
			'double line',
			'thin and thick double line',
			'thick and thin double line',
			'wave',
			'double wave',
			'thick 3d',
			'negative thick 3d',
			'3d',
			'negative 3d'
		]

		BORDER_LINE_WIDTH = [
			'0.1mm',
			'0.12mm',
			'0.15mm',
			'0.2mm',
			'0.25mm',
			'0.3mm',
			'0.4mm',
			'0.5mm',
			'0.6mm',
			'0.7mm',
			'1.0mm',
			'1.5mm',
			'2.0mm',
			'3.0mm',
			'4.0mm',
			'5.0mm'
		]

		DIAGONAL_LINE = [
			'slash',
			'backslash',
			'crooked slash'
		]

		module FillBrush
			class WindowBrush
				attr_reader :face_color,
							:hatch_color,
							:hatch_style
				def initialize data
					@face_color, @hatch_color, @hatch_style = data.unpack("VVV")
				end
			end

			class Gradation
				attr_accessor :type,
							  :angle,
							  :center_x,
							  :center_y,
							  :step,
							  :step_center,
							  :colors
			end

			class ImageBrush
				attr_reader :mode,
							:bright,
							:contrast,
							:effect,
							:bin_item
				def initialize data
					@mode,
					@bright,
					@contrast, @effect, @bin_item = data.unpack("")
				end
			end
		end

		def initialize data, level
			@level = level
			s_io = StringIO.new data

			@bit = s_io.read(1).unpack("b8")

			left_type,  right_type,  top_type,  bottom_type,
			left_width, right_width, top_width, bottom_width,
			left_color, right_color, top_color, bottom_color,
			diagonal_type, diagonal_width, diagonal_color,
			type, size = s_io.read(38).unpack("C8V4CCVVV")

			@slash		= SLASH_TYPE[@bit[2..4]]
			@back_slash	= SLASH_TYPE[@bit[5..7]]

			# type, width, color
			@left_border	= LeftBorder.new(left_type, left_width, left_color)
			@right_border	= RightBorder.new(right_type, right_width, right_color)
			@top_border		= TopBorder.new(top_type,top_width,top_color)
			@bottom_border	= BottomBorder.new(bottom_type,bottom_width,bottom_color)

			@diagonal = Diagonal.new(diagonal_type, diagonal_width, diagonal_color)
			@type = BORDER_LINE_TYPE[type]
			#bignum too big to convert into `long' (RangeError)
			#@size = BORDER_LINE_TYPE[size]
			@gradation = FillBrush::Gradation.new

			if data.bytesize > 40
				@window_brush = FillBrush::WindowBrush.new s_io.read(12)
#				@gradation.type,
#				@gradation.angle,
#				@gradation.center_x,
#				@gradation.center_y,
#				@gradation.step,
#				gradation_color_num = s_io.read(12).unpack("vvvvvv")
#				@gradation.colors = s_io.read(4*gradation_color_num).unpack("V*")
#				@image_brush = FillBrush::ImageBrush.new s_io.read(6)
#				additional_gradation,
#				additional_gradation_center = s_io.read(5).unpack "VC"
			end
			@gradation.step_center = s_io.read(1).unpack("C")[0]
			s_io.close
		end

		def three_d?
			not @bit[0].zero?
		end

		def shadow?
			not @bit[1].zero?
		end
	end

	# TODO REVERSE-ENGINEERING
	# SIZE DISMATCH
	class DocInfo::CharShape
		attr_reader :lang,
					:size,
					:prop,
					:space_between_shadows1,
					:space_between_shadows1,
					:color_letter,
					:color_underline,
					:color_shade,
					:color_shadow,
					:level

		class Lang
			attr_accessor	:font_id,
							:ratio,
							:char_spacing,
							:rel_size,
							:char_offset
		end

		def initialize data, level
			@level = level
			@lang = {
				:korean		=> Lang.new,
				:english	=> Lang.new,
				:hanja		=> Lang.new,
				:japanese	=> Lang.new,
				:others		=> Lang.new,
				:symbol		=> Lang.new,
				:user		=> Lang.new
			}
			@lang[:korean].font_id,
			@lang[:english].font_id,
			@lang[:hanja].font_id,
			@lang[:japanese].font_id,
			@lang[:others].font_id,
			@lang[:symbol].font_id,
			@lang[:user].font_id,

			@lang[:korean].ratio,
			@lang[:english].ratio,
			@lang[:hanja].ratio,
			@lang[:japanese].ratio,
			@lang[:others].ratio,
			@lang[:symbol].ratio,
			@lang[:user].ratio,

			@lang[:korean].char_spacing,
			@lang[:english].char_spacing,
			@lang[:hanja].char_spacing,
			@lang[:japanese].char_spacing,
			@lang[:others].char_spacing,
			@lang[:symbol].char_spacing,
			@lang[:user].char_spacing,

			@lang[:korean].rel_size,
			@lang[:english].rel_size,
			@lang[:hanja].rel_size,
			@lang[:japanese].rel_size,
			@lang[:others].rel_size,
			@lang[:symbol].rel_size,
			@lang[:user].rel_size,

			@lang[:korean].char_offset,
			@lang[:english].char_offset,
			@lang[:hanja].char_offset,
			@lang[:japanese].char_offset,
			@lang[:others].char_offset,
			@lang[:symbol].char_offset,
			@lang[:user].char_offset,

			@size,
			@prop,
			@space_between_shadows1,
			@space_between_shadows1,
			@color_letter,
			@color_underline,
			@color_shade,
			@color_shadow =
				data.unpack("v7 C7 c7 C7 c7 V V c c VVVV")
		end
	end

	# TODO TEST
	class DocInfo::TabDef
		attr_reader :count, :tab_items, :level

		class TabItem
			attr_reader :pos, :type, :leader
			def initialize data
				@pos, @type, @leader = data.unpack("VCC")
			end
		end

		def initialize data, level
			@level = level
			@tab_items = []
			s_io = StringIO.new data
			@bit, @count = s_io.read(6).unpack("b32v")
			s_io.pos += 2 # dummy

			@count.times do
				@tab_items << TabItem.new(s_io.read 6)
				s_io.pos += 2 # dummy
			end
			s_io.close
		end

		def auto_tab_left?
			not @bit[0].zero?
		end

		def auto_tab_right?
			not @bit[1].zero?
		end
	end

	class DocInfo::Numbering
		attr_reader :level, :numbering, :start_num
		def initialize data, level
			@level = level
			@numbering = []
			s_io = StringIO.new data
			# 7단계이어서 7번 반복하지만, numbering 개수가 나오는 헤더가 있는지 확인해야 한다.
			7.times do
				# TODO 속성
				s_io.read 12
				len = s_io.read(2).unpack("v").pop
				@numbering << s_io.read(2*len).unpack("v*").pack("U*")
			end
			@start_num = s_io.read(2).unpack("v").pop
		end

		def debug
			print "\t"*@level + "Numbering:"
			puts @numbering.to_s + " " + @start_num.to_s
		end
	end

	class DocInfo::Bullet
		attr_reader :level
		def initialize data, level
			@level = level
			raise NotImplementedError.new "DocInfo::Bullet"
		end
	end

	# TODO REVERSE-ENGINEERING
	class DocInfo::ParaShape
		attr_reader :level
		def initialize data, level
			@level = level
			s_io = StringIO.new data
			s_io.read(4).unpack("b32") # property
			# PARA MARGIN
			left = s_io.read(4).unpack("V")
			right = s_io.read(4).unpack("V")
			indent = s_io.read(4).unpack("V")
			prev = s_io.read(4).unpack("V")
			_next = s_io.read(4).unpack("V")
			line_spacing = s_io.read(4).unpack("V")
			s_io.read(2).unpack("v")
			heading = s_io.read(2).unpack("v")
			# PARA BORDER
			s_io.read(2).unpack("v")
			s_io.read(2).unpack("v")
			s_io.read(2).unpack("v")
			s_io.read(2).unpack("v")
			s_io.read(2).unpack("v")
			# FIXME SIZE DISMATCH
			#p s_io.read(4).unpack("V")
			#p s_io.read(4).unpack("V")
			#p s_io.read(4).unpack("V")
			#p s_io.pos
			s_io.close
		end
	end

	class DocInfo::Style
		attr_reader :level

		def initialize data, level
			@level = level
			s_io = StringIO.new data
			len = s_io.read(2).unpack('v')[0]
			name = s_io.read(len*2).unpack('v*').pack("U*")
			len = s_io.read(2).unpack('v')[0]
			eng_name = s_io.read(len*2).unpack('v*').pack("U*")
			bit, next_style_id = s_io.read(2).unpack('b8C')

			lang_id = s_io.read(2).unpack('v') # TODO TEST
			para_shape_id, char_shape_id = s_io.read(4).unpack('vv')
			lock_form = s_io.read(2).unpack('v') # TODO TEST
		end
	end

	# TODO REVERSE-ENGINEERING
	class DocInfo::DocData
		attr_reader :level

		def initialize data, level
			@level = level
			#p data.bytesize # => 72
			s_io = StringIO.new data
			param_set_id = s_io.read(2).unpack("v")#.pack("U")
			count = s_io.read(2).unpack("v")[0]
			param_item_id = s_io.read(2).unpack("v")[0]
			#bit = s_io.read(2).unpack("b16")[0]
			s_io.close
		end
	end

	class DocInfo::DistributeDocData
		attr_reader :level

		def initialize data, level
			@level = level
			raise NotImplementedError.new "DocInfo::DistributeDocData"
		end
	end

	class DocInfo::Reserved
		attr_reader :level

		def initialize data, level
			@level = level
			raise NotImplementedError.new "DocInfo::Reserved"
		end
	end

	class DocInfo::CompatibleDocument
		attr_reader :level

		def initialize data, level
			@level = level
			raise NotImplementedError.new "DocInfo::CompatibleDocument"
		end
	end

	class DocInfo::LayoutCompatibility
		attr_reader :level

		def initialize data, level
			@level = level
			raise NotImplementedError.new "DocInfo::LayoutCompatibility"
		end
	end

	class DocInfo::ForbiddenChar
		attr_reader :level

		def initialize data, level
			@level = level
			raise NotImplementedError.new "DocInfo::ForbiddenChar"
		end
	end
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
