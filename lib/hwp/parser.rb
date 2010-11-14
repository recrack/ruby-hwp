# (주)한글과컴퓨터의 한컴오피스 hwp 문서 파일 구조 공개정책에 따라 이루어졌습니다.
# 이렇게 말하면 ruby-hwp 개발자가 (주)한글과컴퓨터社와 어떤 관계가 있는 것처럼 오해받을 수 있지만
# hwp 스펙 문서 11쪽 저작권 관련 내용을 보면 이렇게 표시하라고 해서 이렇게 표시했을 뿐입니다.
# ruby-hwp는 (주)한글과컴퓨터社가 만든 것이 아니며, (주)한글과컴퓨터社가 지원하지 않으며, (주)한글과컴퓨터社가 유지보수하지 않습니다.
# Note that ruby-hwp is not manufactured, approved, supported, maintained by Hancom Inc.
# ruby-hwp 개발자는 (주)한글과컴퓨터社와 아무런 관련이 없습니다.
# ruby-hwp 및 ruby-hwp 관련 문서 내용을 사용하여 발생된 모든 결과에 대하여 책임지지 않습니다.
# NO WARRANTY

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
			bytes = @stream.read(HWP::DWORD)	# 레코드 헤더를 읽는다
			Record::Header.decode(bytes)
			data = @stream.read(Record::Header.size)

			case HWPTAGS[Record::Header.tag_id]
			# doc info
			when :HWPTAG_DOCUMENT_PROPERTIES
				# 스펙 오류
				Record::Data::DocumentProperties.new data
			when :HWPTAG_ID_MAPPINGS
				Record::Data::IDMappings.new data
			when :HWPTAG_BIN_DATA
				Record::Data::BinData.new data
			when :HWPTAG_FACE_NAME
				Record::Data::FaceName.new data
			when :HWPTAG_BORDER_FILL
				Record::Data::BorderFill.new data
			when :HWPTAG_CHAR_SHAPE
				Record::Data::CharShape.new data
			when :HWPTAG_TAB_DEF
				Record::Data::TabDef.new data
			when :HWPTAG_NUMBERING
				Record::Data::Numbering.new data
			when :HWPTAG_BULLET
				Record::Data::Bullet.new data
			when :HWPTAG_PARA_SHAPE
				Record::Data::ParaShape.new data
			when :HWPTAG_STYLE
				Record::Data::Style.new data
			when :HWPTAG_DOC_DATA
				Record::Data::DocData.new data
			when :HWPTAG_DISTRIBUTE_DOC_DATA
				Record::Data::DistributeDocData.new data
			when :RESERVED
				Record::Data::Reserved.new data
			when :HWPTAG_COMPATIBLE_DOCUMENT
				Record::Data::CompatibleDocument.new data
			when :HWPTAG_LAYOUT_COMPATIBILITY
				Record::Data::LayouCompatibility.new data
			when :HWPTAG_FORBIDDEN_CHAR
				Record::Data::ForbiddenChar.new data
			# body text
			when :HWPTAG_PARA_HEADER		then	Record::Data::ParaHeader.new data
			when :HWPTAG_PARA_TEXT			then	Record::Data::ParaText.new data
			when :HWPTAG_PARA_CHAR_SHAPE	then	Record::Data::ParaCharShape.new data
			when :HWPTAG_PARA_LINE_SEG		then	Record::Data::ParaLineSeg.new data
			when :HWPTAG_PARA_RANGE_TAG		then	Record::Data::ParaRangeTag.new data
			when :HWPTAG_CTRL_HEADER		then	Record::Data::CtrlHeader.new data
			when :HWPTAG_LIST_HEADER		then	Record::Data::ListHeader.new data
			when :HWPTAG_PAGE_DEF			then	Record::Data::PageDef.new data
			when :HWPTAG_FOOTNOTE_SHAPE		then	Record::Data::FootnoteShape.new data
			when :HWPTAG_PAGE_BORDER_FILL	then	Record::Data::PageBorderFill.new data
			when :HWPTAG_SHAPE_COMPONENT	then	Record::Data::ShapeComponent.new data
			when :HWPTAG_TABLE				then	Record::Data::Table.new data
			when :HWPTAG_SHAPE_COMPONENT_LINE		then	Record::Data::ShapeComponentLine.new data
			when :HWPTAG_SHAPE_COMPONENT_RECTANGLE	then	Record::Data::ShapeComponentRectangle.new data
			when :HWPTAG_SHAPE_COMPONENT_ELLIPSE	then	Record::Data::ShapeComponentEllipse.new data
			when :HWPTAG_SHAPE_COMPONENT_ARC		then	Record::Data::ShapeComponentArc.new data
			when :HWPTAG_SHAPE_COMPONENT_POLYGON	then	Record::Data::ShapeComponentPolygon.new data
			when :HWPTAG_SHAPE_COMPONENT_CURVE		then	Record::Data::ShapeComponentCurve.new data
			when :HWPTAG_SHAPE_COMPONENT_OLE		then	Record::Data::ShapeComponentOle.new data
			when :HWPTAG_SHAPE_COMPONENT_PICTURE	then	Record::Data::ShapeComponentPicture.new data
			when :HWPTAG_SHAPE_COMPONENT_CONTAINER	then	Record::Data::ShapeComponentContainer.new data
			when :HWPTAG_CTRL_DATA			then	Record::Data::CtrlData.new data
			when :HWPTAG_EQEDIT				then	Record::Data::EQEdit.new data
			when :RESERVED					then	Record::Data::Reserved.new data
			when :HWPTAG_SHAPE_COMPONENT_TEXTART	then	Record::Data::ShapeComponentTextart.new data
			when :HWPTAG_FORM_OBJECT	then	Record::Data::FormObject.new data
			when :HWPTAG_MEMO_SHAPE		then	Record::Data::MemoShape.new data
			when :HWPTAG_MEMO_LIST		then	Record::Data::MemoList.new data
			when :HWPTAG_CHART_DATA		then	Record::Data::ChartData.new data
			when :HWPTAG_SHAPE_COMPONENT_UNKNOWN	then	Record::Data::ShapeComponentUnknown.new data
			else
				raise "Unknown tag: #{HWPTAGS[Record::Header.tag_id]}"
			end
		end # pull
	end # class Parser
end
