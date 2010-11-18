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

		# TODO remove s_io, use unpack "x"
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
					:size

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

		def initialize data
			@bit,
			left_type,  right_type,  top_type,  bottom_type,
			left_width, right_width, top_width, bottom_width,
			left_color, right_color, top_color, bottom_color,
			diagonal_type, diagonal_width, diagonal_color,
			type, size = data.unpack("b8 CCCC CCCC VVVV CCV V V")

			@slash		= SLASH_TYPE[@bit[2..4]]
			@back_slash	= SLASH_TYPE[@bit[5..7]]

			@left_border	= LeftBorder.new(left_border, left_type, left_width)
			@right_border	= RightBorder.new(right_border, right_type, right_width)
			@top_border		= TopBorder.new(top_border,top_type,top_width)
			@bottom_border	= BottomBorder.new(bottom_border,bottom_type,bottom_width)

			@left_border = LeftBorder.new left_type, left_width, left_color
			@right_border = RightBorder.new(right_type, right_width, right_color)
			@top_border = TopBorder.new top_type, top_width, top_color
			@bottom_border = BottomBorder.new(bottom_type, bottom_width, bottom_color)
			@diagonal = Diagonal.new(diagonal_type, diagonal_width, diagonal_color)
			@type = BORDER_LINE_TYPE[type]
			@size = BORDER_LINE_TYPE[size]
			# FIXME
			gradation_step_center = data[-1].unpack("C")[0]
			# TODO make sub class
			if data.bytesize > 40
				face_color,
				hatch_color,
				hatch_style,
				gradation_type,
				gradation_angle,
				gradation_center_x,
				gradation_center_y,
				gradation_step,
				gradation_color_num = data.unpack("x39 VVV vvvvvv")[0]
				gradation_colors = data.unpack "x63 V#{gradation_color_num}"
				image_brush_mode,
				bright,
				contrast,
				effect,
				bin_item_id,
				additional_gradation,
				additional_gradation_center = data.unpack "x#{67+4*gradation_color_num} C cccv VC"
			end
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

	# TODO REVERSE-ENGINEERING
	class DocInfo::TabDef
		def initialize data
			#p data.bytesize
			#p data.unpack("V v V C C v")
		end
	end

	class DocInfo::Numbering
		def initialize data
		end
	end

	class DocInfo::Bullet
		def initialize data
		end
	end

	# TODO REVERSE-ENGINEERING
	class DocInfo::ParaShape
		def initialize data
			#p data.bytesize
			#p data.unpack("b32VVVVVVvvvvvvvVVV")
		end
	end

	# TODO REVERSE-ENGINEERING
	class DocInfo::Style
		def initialize data
			#p data.bytesize
			len1 = data.unpack("v")[0]
			local_style_name = data.unpack("x2 v#{len1}").pack("U*")
			len2 = data.unpack("x#{2+2*len1} v")[0]
			data.unpack("x#{4+2*len1} v#{len2}").pack("U*")
			data.unpack("x#{4+2*len1+2*len2} ccsvv")
		end
	end

	# TODO REVERSE-ENGINEERING
	class DocInfo::DocData
		def initialize data
			s_io = StringIO.new data
			param_set_id = s_io.read(2)
			n = s_io.read(2).unpack("c")[0]

			param_item_id = s_io.read(2)
			param_item_type = s_io.read(2).unpack("CC")

			param_item_type[0]
			param_item_type[1] & 0x8000
			param_item_type[1] & 0x8001
			param_item_type[1] & 0x8002
			s_io.close
		end
	end

	# TODO REVERSE-ENGINEERING
	class DocInfo::DistributeDocData
		def initialize data
		end
	end

	class DocInfo::Reserved
		def initialize data
		end
	end

	class DocInfo::CompatibleDocument
		def initialize data
		end
	end

	class DocInfo::LayoutCompatibility
		def initialize data
		end
	end

	class DocInfo::ForbiddenChar
		def initialize data
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
			@ref_para_shape_id,
			@ref_para_style_id,
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
			@start, @end, @tag = data.unpack("VVb*")
		end
	end

	# TODO REVERSE-ENGINEERING
	class CtrlHeader
		attr_accessor :ctrl_id
		def initialize data
		end
	end

	class ListHeader
		attr_accessor :num_para, :property
		def initialize data
		end
	end

	class CtrlData
		attr_accessor :var
		def initialize data
		end
	end

	# TODO REVERSE-ENGINEERING
	class Table
		def initialize data
			prop,
			row_count,
			n_cols,
			cell_spacing,
			margin1,
			margin2,
			margin3,
			margin4 = data.unpack("Vvvvvvvv")
			row_size = data.unpack("x18 C#{2*row_count} CC")
			border_fill_id,
			valid_zone_info_size = 
				data.unpack("x#{18+2*row_count} CC")
		end
	end

	class PageDef
		def initialize data
			# I | HWPUNIT unsigned int
			horizontal_size,	vertical_size,	left_margin,
			right_margin,		top_margin,		bottom_margin,
			head_margin,		foot_margin,	binding_margin,
			property = data.unpack("IIIIIIIIII")
			#print "PageDef: "; p array
		end
	end

	class FootnoteShape
		def initialize data
			#p self
			# 스펙 문서 57쪽 크기 불일치 26 != 28
			#p data.unpack("ISSSSSSSSCCIS") # 마지막 2바이트 S, 총 28바이트
		end
	end

	class PageBorderFill
		def initialize data
			#p self
			# 스펙 문서 58쪽 크기 불일치 12 != 14
			#p data.unpack("ISSSSS") # 마지막 2바이트 S, 총 14바이트
		end
	end

	# TODO REVERSE-ENGINEERING
	class ShapeComponent
		def initialize data
			#ctrl_id = data.unpack("CCCC").pack("U*").reverse
			#p data.unpack("CCCCCCCC").pack("U*").reverse
			#p data.unpack("x8 iivvVVVVVvii")
		end
	end

	class ShapeComponentLine;end
	class ShapeComponentRectangle;end
	class ShapeComponentEllipse;end
	class ShapeComponentArc;end
	class ShapeComponentPolygon;end
	class ShapeComponentCurve;end
	class ShapeComponentOLE;end

	# TODO REVERSE-ENGINEERING
	class ShapeComponentPicture
		def initialize data
			data.unpack("V6sv4Vv vV vVvV")
		end
	end

	class ShapeComponentContainer;end

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

	class Reserved;end
	class ShapeComponentTextArt;end
	class FormObject;end
	class MemoShape;end
	class MemoList;end
	class ChartData;end
	class ShapeComponentUnknown;end
end # Record::Section
