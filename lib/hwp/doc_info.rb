require 'zlib'

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
                    :para_shapes,
                    :styles,
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
            @para_shapes            = []
            @styles                 = []
            @doc_data				= []
            @distribute_doc_data	= []
            @reserved				= []
            @compatible_document	= []
            @layout_compatibility	= []
            @forbidden_char			= []

            parser = HWP::Parser.new @doc_info
            while parser.has_next?
                parser.pull
                case parser.tag_id
                when :HWPTAG_DOCUMENT_PROPERTIES
                    @document_properties << Record::DocInfo::DocumentProperties.
                        new(parser.data, parser.level)
                when :HWPTAG_ID_MAPPINGS
                    @id_mappings << Record::DocInfo::IDMappings.
                        new(parser.data, parser.level)
                when :HWPTAG_BIN_DATA
                    @bin_data <<
                        Record::DocInfo::BinData.new(parser.data, parser.level)
                when :HWPTAG_FACE_NAME
                    @face_names <<
                        Record::DocInfo::FaceName.new(parser.data, parser.level)
                when :HWPTAG_BORDER_FILL
                    @border_fill << Record::DocInfo::BorderFill.
                        new(parser.data, parser.level)
                when :HWPTAG_CHAR_SHAPE
                    @char_shapes << Record::DocInfo::CharShape.
                        new(parser.data, parser.level)
                when :HWPTAG_TAB_DEF
                    @tab_def <<
                        Record::DocInfo::TabDef.new(parser.data, parser.level)
                when :HWPTAG_NUMBERING
                    @numbering << Record::DocInfo::Numbering.
                        new(parser.data, parser.level)
                when :HWPTAG_BULLET
                    @bullet <<
                        Record::DocInfo::Bullet.new(parser.data, parser.level)
                when :HWPTAG_PARA_SHAPE
                    @para_shapes << Record::DocInfo::ParaShape.
                        new(parser.data, parser.level)
                when :HWPTAG_STYLE
                    @styles <<
                        Record::DocInfo::Style.new(parser.data, parser.level)
                when :HWPTAG_DOC_DATA
                    @doc_data <<
                        Record::DocInfo::DocData.new(parser.data, parser.level)
                when :HWPTAG_DISTRIBUTE_DOC_DATA
                    @distribute_doc_data << Record::DocInfo::DistributeDocData.
                        new(parser.data, parser.level)
                when :RESERVED
                    @reserved <<
                        Record::DocInfo::Reserved.new(parser.data, parser.level)
                when :HWPTAG_COMPATIBLE_DOCUMENT
                    @compatible_document << Record::DocInfo::CompatibleDocument.
                        new(parser.data, parser.level)
                when :HWPTAG_LAYOUT_COMPATIBILITY
                    @layout_compatibility <<
                        Record::DocInfo::LayoutCompatibility.
                            new(parser.data, parser.level)
                when :HWPTAG_MEMO_SHAPE
                    # TODO
                when :HWPTAG_DOC_INFO_16 # 레이아웃 관련 태그로 추정됨.
                    # TODO
                when :HWPTAG_FORBIDDEN_CHAR
                    @forbidden_char << Record::DocInfo::ForbiddenChar.
                        new(parser.data, parser.level)
                else
                    raise "UNKNOWN RECORD"
                end
            end # while
        end # initialize
    end # DocInfo


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
			#@gradation.step_center = s_io.read(1).unpack("C")[0]
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
		attr_reader :level, :left, :right
		def initialize data, level
			@level = level
			s_io = StringIO.new data
			s_io.read(4).unpack("b32") # property
			# PARA MARGIN
			@left = s_io.read(4).unpack("V")[0]
			@right = s_io.read(4).unpack("V")[0]
			indent = s_io.read(4).unpack("V")[0]
			prev = s_io.read(4).unpack("V")[0]
			_next = s_io.read(4).unpack("V")[0]
			line_spacing = s_io.read(4).unpack("V")[0]
			s_io.read(2).unpack("v")[0]
			heading = s_io.read(2).unpack("v")[0]
			# PARA BORDER
			s_io.read(2).unpack("v")[0]
			s_io.read(2).unpack("v")[0]
			s_io.read(2).unpack("v")[0]
			s_io.read(2).unpack("v")[0]
			s_io.read(2).unpack("v")[0]
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
			#raise NotImplementedError.new "DocInfo::CompatibleDocument"
		end
	end

	class DocInfo::LayoutCompatibility
		attr_reader :level

		def initialize data, level
			@level = level
			#raise NotImplementedError.new "DocInfo::LayoutCompatibility"
		end
	end

	class DocInfo::ForbiddenChar
		attr_reader :level

		def initialize data, level
			@level = level
            # 금칙 문자는 뷰어에서 출력할 필요가 없다.
            # TODO 금칙 문자의 데이터 형식은?
            forbidden = data.unpack("v*").pack("U*")
		end
	end
end
