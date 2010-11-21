# (주)한글과컴퓨터의 한컴오피스 hwp 문서 파일 구조 공개정책에 따라 이루어졌습니다.
# 이렇게 말하면 ruby-hwp 개발자가 (주)한글과컴퓨터社와 어떤 관계가 있는 것처럼 오해받을 수 있지만
# hwp 스펙 문서 11쪽 저작권 관련 내용을 보면 이렇게 표시하라고 해서 이렇게 표시했을 뿐입니다.
# ruby-hwp는 (주)한글과컴퓨터社가 만든 것이 아니며, (주)한글과컴퓨터社가 지원하지 않으며,
# (주)한글과컴퓨터社가 유지보수하지 않습니다.
# Note that ruby-hwp is
# not manufactured, not approved, not supported, not maintained by Hancom Inc.
# ruby-hwp 개발자는 (주)한글과컴퓨터社와 아무런 관련이 없습니다.
# ruby-hwp 및 ruby-hwp 관련 문서 내용을 사용하여 발생된 모든 결과에 대하여 책임지지 않습니다.
# NO WARRANTY

require 'iconv'
require 'stringio'
require 'hwp/datatypes'

# TODO close StringIO instances

module Record;end
module Record
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
			if header.gzipped?
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
				case response.class.to_s
				when "Record::DocInfo::DocumentProperties"
					@document_properties << response
				when "Record::DocInfo::IDMappings"
					@id_mappings << response
				when "Record::DocInfo::BinData"
					@bin_data << response
				when "Record::DocInfo::FaceName"
					@face_names << response
				when "Record::DocInfo::BorderFill"
					@border_fill << response
				when "Record::DocInfo::CharShape"
					@char_shapes << response
				when "Record::DocInfo::TabDef"
					@tab_def << response
				when "Record::DocInfo::Numbering"
					@numbering << response
				when "Record::DocInfo::Bullet"
					@bullet << response
				when "Record::DocInfo::ParaShape"
					@para_shape << response
				when "Record::DocInfo::Style"
					@style << response
				when "Record::DocInfo::DocData"
					@doc_data << response
				when "Record::DocInfo::DistributeDocData"
					@distribute_doc_data << response
				when "Record::DocInfo::Reserved"
					@reserved << response
				when "Record::DocInfo::CompatibleDocument"
					@compatible_document << response
				when "Record::DocInfo::LayoutCompatibility"
					@layout_compatibility << response
				when "Record::DocInfo::ForbiddenChar"
					@forbidden_char << response
				else
					raise "UNKNOWN RECORD"
				end
			end
		end
	end
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
					:caret_pos_char_pos

		def initialize data
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
					:memo_shape_count

		def initialize data
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
					:status			# deprecated method

		def initialize data
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
					:font_type_info

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

		def initialize data
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

	# TODO REVERSE-ENGINEERING
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
					:image_brush

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

		def initialize data
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
			@size = BORDER_LINE_TYPE[size]
			@gradation = FillBrush::Gradation.new

			if data.bytesize > 40
				@window_brush = FillBrush::WindowBrush.new s_io.read(12)
				@gradation.type,
				@gradation.angle,
				@gradation.center_x,
				@gradation.center_y,
				@gradation.step,
				gradation_color_num = s_io.read(12).unpack("vvvvvv")
				@gradation.colors = s_io.read(4*gradation_color_num).unpack("V*")
				@image_brush = FillBrush::ImageBrush.new s_io.read(6)
				additional_gradation,
				additional_gradation_center = s_io.read(5).unpack "VC"
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

	class DocInfo::CharShape
		attr_reader :lang,
					:ratio,
					:char_spacing,
					:rel_size,
					:char_offset,
					:size,
					:prop,
					:space_between_shadows1,
					:space_between_shadows1,
					:color_letter,
					:color_underline,
					:color_shade,
					:color_shadow

		class Lang
			attr_accessor	:font_id,
							:ratio,
							:char_spacing,
							:rel_size,
							:char_offset
		end

		def initialize data
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
		attr_reader :count, :tab_items

		class TabItem
			attr_reader :pos, :type, :leader
			def initialize data
				@pos, @type, @leader = data.unpack("VCC")
			end
		end

		def initialize data
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
		def initialize data
			raise NotImplementedError.new "DocInfo::Numbering"
		end
	end

	class DocInfo::Bullet
		def initialize data
			raise NotImplementedError.new "DocInfo::Bullet"
		end
	end

	# TODO REVERSE-ENGINEERING
	class DocInfo::ParaShape
		def initialize data
			#raise NotImplementedError.new "DocInfo::ParaShape"
			#p data.bytesize
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
		def initialize data
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
		def initialize data
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
		def initialize data
			raise NotImplementedError.new "DocInfo::DistributeDocData"
		end
	end

	class DocInfo::Reserved
		def initialize data
			raise NotImplementedError.new "DocInfo::Reserved"
		end
	end

	class DocInfo::CompatibleDocument
		def initialize data
			raise NotImplementedError.new "DocInfo::CompatibleDocument"
		end
	end

	class DocInfo::LayoutCompatibility
		def initialize data
			raise NotImplementedError.new "DocInfo::LayoutCompatibility"
		end
	end

	class DocInfo::ForbiddenChar
		def initialize data
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
					:para_instance_id

		def initialize data
			@chars,
			@control_mask,
			@para_shape_id,
			@para_style_id,
			@column_type,
			@num_char_shape,
			@num_range_tag,
			@num_align,
			@para_instance_id = data.unpack("VVvCCvvvV")
		end
	end

	class ParaText
		def initialize data
			s_io = StringIO.new data
			@byte_str = ""

			while(ch = s_io.read(2))
				case ch.unpack("v")[0]
				# 2-byte control string
				when 0,10,13,24,25,26,27,28,29,31
					#@byte_str << ch
				when 30 # 0x1e record separator (RS)
					@byte_str << " \x00"

				# 16-byte control string, inline
				when 4,5,6,7,8,19,20
					s_io.pos = s_io.pos + 14
				when 9 # tab
					@byte_str << "\t\x00"
					s_io.pos = s_io.pos + 14

				# 16-byte control string, extended
				when 1,2,3,11,12,14,15,16,17,18,21,22,23
					s_io.pos = s_io.pos + 14

				# TODO mapping table
				# 유니코드 문자 교정, 한자 영역 등의 다른 영역과 겹칠지도 모른다.
				# L filler utf-16 값 "_\x11"
				when 0xf784 # "\x84\xf7
					@byte_str << "_\x11"
				# V ㅘ		utf-16 값 "j\x11"
				when 0xf81c # "\x1c\xf8"
					@byte_str << "j\x11"
				# V ㅙ		utf-16 값 "k\x11"
				when 0xf81d # "\x1d\xf8"
					@byte_str << "k\x11"
				# V ㅝ		utf-16 값 "o\x11"
				when 0xf834 # "\x34\xf8" "4\xf8"
					@byte_str << "o\x11"
				# T ㅆ		utf-16 값 "\xBB\x11"
				when 0xf8cd # "\xcd\xf8"
					@byte_str << "\xBB\x11"
				else
					@byte_str << ch
				end
			end
			s_io.close
		end

		def to_s
			@byte_str.unpack("v*").pack("U*")
		end
	end # class ParaText

	class ParaCharShape
		attr_accessor :m_pos, :m_id

		def initialize data
			@m_pos = []
			@m_id = []
			n = data.bytesize / 4
			array = data.unpack("I" * n)
			array.each_with_index do |element, i|
				@m_pos << element if (i % 2) == 0
				@m_id  << element if (i % 2) == 1
			end
		end
	end

	# TODO REVERSE-ENGINEERING
	class ParaLineSeg
		def initialize data
		end
	end

	class ParaRangeTag
		attr_accessor :start, :end, :tag
		def initialize data
			raise NotImplementedError.new "Record::Section::ParaRangeTag"
			#@start, @end, @tag = data.unpack("VVb*")
		end
	end

	# TODO REVERSE-ENGINEERING
	class CtrlHeader
		attr_accessor :ctrl_id
		def initialize data
			s_io = StringIO.new data
			ctrl_id = s_io.read(4).unpack("C4").pack("U*").reverse
			#p s_io.read.unpack("v*")
			s_io.close
		end
	end

	# TODO REVERSE-ENGINEERING
	class ListHeader
		attr_accessor :num_para, :property
		def initialize data
			s_io = StringIO.new data
			s_io.read(2).unpack("v")
			#p data.bytesize
			# 바이트가 남는다
			s_io.close
		end
	end

	class CtrlData
		attr_accessor :var
		def initialize data
			raise NotImplementedError.new "Record::Section::CtrlData"
		end
	end

	# TODO REVERSE-ENGINEERING
	class Table
		def initialize data
			s_io = StringIO.new data
			prop = s_io.read(4).unpack("V")
			row_count = s_io.read(2).unpack("v")[0]
			n_cols = s_io.read(2).unpack("v")[0]
			cell_spacing = s_io.read(2).unpack("v")
			margin1 = s_io.read(2).unpack("v")
			margin2 = s_io.read(2).unpack("v")
			margin3 = s_io.read(2).unpack("v")
			margin4 = s_io.read(2).unpack("v")
			row_size = s_io.read(2*row_count).unpack("v*")
			border_fill_id = s_io.read(2).unpack("v")
			#valid_zone_info_size = s_io.read(2).unpack("v")[0]
			#zone_prop = s_io.read(10*valid_zone_info_size).unpack("v*")
			s_io.close
		end
	end

	class ShapeComponent
		attr_reader :scale_matrices, :rotate_matrices
		FLIP_TYPE = ['horz flip', 'vert flip']

		def initialize data
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
		def initialize data
			raise NotImplementedError.new "Record::Section::ShapeComponentLine"
		end
	end

	class ShapeComponentRectangle
		def initialize data
			raise NotImplementedError.new "Record::Section::ShapeComponentRectangle"
		end
	end

	class ShapeComponentEllipse
		def initialize data
			raise NotImplementedError.new "Record::Section::ShapeComponentEllipse"
		end
	end
	
	class ShapeComponentArc
		def initialize data
			raise NotImplementedError.new "Record::Section::ShapeComponentArc"
		end
	end

	class ShapeComponentPolygon
		def initialize data
			raise NotImplementedError.new "Record::Section::ShapeComponentPolygon"
		end
	end
	
	class ShapeComponentCurve
		def initialize data
			raise NotImplementedError.new "Record::Section::ShapeComponentCurve"
		end
	end
	
	class ShapeComponentOLE
		def initialize data
			raise NotImplementedError.new "Record::Section::ShapeComponentOLE"
		end
	end

	# TODO REVERSE-ENGINEERING
	class ShapeComponentPicture
		def initialize data
			p data.unpack("V6sv4Vv vV vVvV")
		end
	end

	class ShapeComponentContainer
		def initialize data
			raise NotImplementedError.new "Record::Section::ShapeComponentContainer"
		end
	end

	class ShapeComponentTextArt
		def initialize data
			raise NotImplementedError.new "Record::Section::ShapeComponentTextArt"
		end
	end

	class ShapeComponentUnknown
		def initialize data
			raise NotImplementedError.new "Record::Section::ShapeComponentUnknown"
		end
	end

	class PageDef
		def initialize data
			width,	height,
			left_margin,	right_margin,
			top_margin,		bottom_margin,
			header_margin,	footer_margin,
			gutter_margin,	property = data.unpack("V*")
		end
	end

	# TODO REVERSE-ENGINEERING
	class FootnoteShape
		def initialize data
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
	end

	class PageBorderFill
		def initialize data
			# 스펙 문서 58쪽 크기 불일치 12 != 14
			#p data.unpack("ISSSSS") # 마지막 2바이트 S, 총 14바이트
		end
	end

	class EQEdit
		# TODO DOT 훈DOT 민 DOT 정 DOT 음
		def initialize data
			io = StringIO.new(data)
			property = io.read(4).unpack("I")	# INT32
			len = io.read(2).unpack("s")[0]	# WORD
			#io.read(len * 2).unpack("S*").pack("U*")		# WCHAR
			@script = Iconv.iconv("utf-8", "utf-16", io.read(len * 2))[0].chomp		# WCHAR
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
		def initialize data
			raise NotImplementedError.new "Record::Section::ShapeComponentUnknown"
		end
	end

	class FormObject
		def initialize data
			raise NotImplementedError.new "Record::Section::FormObject"
		end
	end

	class MemoShape
		def initialize data
			raise NotImplementedError.new "Record::Section::MemoShape"
		end
	end

	class MemoList
		def initialize data
			raise NotImplementedError.new "Record::Section::MemoList"
		end
	end

	class ChartData
		def initialize data
			raise NotImplementedError.new "Record::Section::ChartData"
		end
	end
end # Record::Section
