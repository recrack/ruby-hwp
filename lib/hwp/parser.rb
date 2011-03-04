# coding: utf-8
# 한글과컴퓨터의 글 문서 파일(.hwp) 공개 문서를 참고하여 개발하였습니다.

module HWP
	class Parser
		def initialize stream
			@stream = stream
			@stack = []
		end

		def has_next?
			not @stream.eof?
		end

		def pop
			@stack.pop
		end

		def push token
			@stack.push token
		end

		def pull
			bytes = @stream.read(4)	# 레코드 헤더를 읽는다
			Record::Header.decode(bytes)
			data = @stream.read(Record::Header.size)
			level = Record::Header.level

			case HWPTAGS[Record::Header.tag_id]
			# doc info
			when :HWPTAG_DOCUMENT_PROPERTIES
				Record::DocInfo::DocumentProperties.new(data, level)
			when :HWPTAG_ID_MAPPINGS
				Record::DocInfo::IDMappings.new(data, level)
			when :HWPTAG_BIN_DATA
				Record::DocInfo::BinData.new(data, level)
			when :HWPTAG_FACE_NAME
				Record::DocInfo::FaceName.new(data, level)
			when :HWPTAG_BORDER_FILL
				Record::DocInfo::BorderFill.new(data, level)
			when :HWPTAG_CHAR_SHAPE
				Record::DocInfo::CharShape.new(data, level)
			when :HWPTAG_TAB_DEF
				Record::DocInfo::TabDef.new(data, level)
			when :HWPTAG_NUMBERING
				Record::DocInfo::Numbering.new(data, level)
			when :HWPTAG_BULLET
				Record::DocInfo::Bullet.new(data, level)
			when :HWPTAG_PARA_SHAPE
				Record::DocInfo::ParaShape.new(data, level)
			when :HWPTAG_STYLE
				Record::DocInfo::Style.new(data, level)
			when :HWPTAG_DOC_DATA
				Record::DocInfo::DocData.new(data, level)
			when :HWPTAG_DISTRIBUTE_DOC_DATA
				Record::DocInfo::DistributeDocData.new(data, level)
			when :RESERVED
				Record::DocInfo::Reserved.new(data, level)
			when :HWPTAG_COMPATIBLE_DOCUMENT
				Record::DocInfo::CompatibleDocument.new(data, level)
			when :HWPTAG_LAYOUT_COMPATIBILITY
				Record::DocInfo::LayoutCompatibility.new(data, level)
			when :HWPTAG_FORBIDDEN_CHAR
				Record::DocInfo::ForbiddenChar.new(data, level)
			# body text
			when :HWPTAG_PARA_HEADER		then	Record::Section::ParaHeader.new(data, level)
			when :HWPTAG_PARA_TEXT			then	Record::Section::ParaText.new(data, level)
			when :HWPTAG_PARA_CHAR_SHAPE	then	Record::Section::ParaCharShape.new(data, level)
			when :HWPTAG_PARA_LINE_SEG		then	Record::Section::ParaLineSeg.new(data, level)
			when :HWPTAG_PARA_RANGE_TAG		then	Record::Section::ParaRangeTag.new(data, level)
			when :HWPTAG_CTRL_HEADER		then	Record::Section::Modeller.new(data, level)
			when :HWPTAG_LIST_HEADER		then	Record::Section::ListHeader.new(data, level)
			when :HWPTAG_PAGE_DEF			then	Record::Section::PageDef.new(data, level)
			when :HWPTAG_FOOTNOTE_SHAPE		then	Record::Section::FootnoteShape.new(data, level)
			when :HWPTAG_PAGE_BORDER_FILL	then	Record::Section::PageBorderFill.new(data, level)
			when :HWPTAG_SHAPE_COMPONENT	then	Record::Section::ShapeComponent.new(data, level)
			when :HWPTAG_TABLE				then	Record::Section::Table.new(data, level)
			when :HWPTAG_SHAPE_COMPONENT_LINE		then	Record::Section::ShapeComponentLine.new(data, level)
			when :HWPTAG_SHAPE_COMPONENT_RECTANGLE	then	Record::Section::ShapeComponentRectangle.new(data, level)
			when :HWPTAG_SHAPE_COMPONENT_ELLIPSE	then	Record::Section::ShapeComponentEllipse.new(data, level)
			when :HWPTAG_SHAPE_COMPONENT_ARC		then	Record::Section::ShapeComponentArc.new(data, level)
			when :HWPTAG_SHAPE_COMPONENT_POLYGON	then	Record::Section::ShapeComponentPolygon.new(data, level)
			when :HWPTAG_SHAPE_COMPONENT_CURVE		then	Record::Section::ShapeComponentCurve.new(data, level)
			when :HWPTAG_SHAPE_COMPONENT_OLE		then	Record::Section::ShapeComponentOLE.new(data, level)
			when :HWPTAG_SHAPE_COMPONENT_PICTURE	then	Record::Section::ShapeComponentPicture.new(data, level)
			when :HWPTAG_SHAPE_COMPONENT_CONTAINER	then	Record::Section::ShapeComponentContainer.new(data, level)
			when :HWPTAG_CTRL_DATA			then	Record::Section::CtrlData.new(data, level)
			when :HWPTAG_EQEDIT				then	Record::Section::EqEdit.new(data, level)
			when :RESERVED					then	Record::Section::Reserved.new(data, level)
			when :HWPTAG_SHAPE_COMPONENT_TEXTART	then	Record::Section::ShapeComponentTextArt.new(data, level)
			when :HWPTAG_FORM_OBJECT	then	Record::Section::FormObject.new(data, level)
			when :HWPTAG_MEMO_SHAPE		then	Record::Section::MemoShape.new(data, level)
			when :HWPTAG_MEMO_LIST		then	Record::Section::MemoList.new(data, level)
			when :HWPTAG_CHART_DATA		then	Record::Section::ChartData.new(data, level)
			when :HWPTAG_SHAPE_COMPONENT_UNKNOWN	then	Record::Section::ShapeComponentUnknown.new(data, level)
			else
				raise "Unknown tag: #{HWPTAGS[Record::Header.tag_id]}"
			end
		end # pull
	end # class Parser
end
