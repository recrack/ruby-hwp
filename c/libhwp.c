/**
(주)한글과컴퓨터의 한컴오피스 hwp 문서 파일 구조 공개정책에 따라 이루어졌습니다.
이렇게 말하면 libhwp 개발자가 (주)한글과컴퓨터社와 어떤 관계가 있는 것처럼 오해받을 수 있지만
hwp 스펙 문서 11쪽 저작권 관련 내용을 보면 이렇게 표시하라고 해서 이렇게 표시했을 뿐입니다.
libhwp는 (주)한글과컴퓨터社가 만든 것이 아니며, (주)한글과컴퓨터社가 지원하지 않으며, (주)한글과컴퓨터社가 유지보수하지 않습니다.
Note that libhwp is not manufactured, approved, supported, maintained by Hancom Inc.
libhwp 개발자는 (주)한글과컴퓨터社와 아무런 관련이 없습니다.
libhwp 및 libhwp 관련 문서 내용을 사용하여 발생된 모든 결과에 대하여 책임지지 않습니다.
NO WARRANTY
**/

#include <stdio.h>

typedef unsigned char	BYTE;     // 1 Byte
typedef unsigned short	WORD;    // 2 Bytes
typedef unsigned long	DWORD;    // 4 Bytes
typedef unsigned short	WCHAR; // 2 Bytes
// typedef HWPUNIT
// typedef SHWPUNIT
typedef unsigned char	UINT8; 
typedef unsigned short	UINT16; 
typedef unsigned int	UINT32;
// typedef UINT32 UINT;
typedef signed char		INT8;
typedef signed short	INT16;
typedef signed int		INT32;
// typedef INT16 HWPUNIT16;
// typedef COLORREF
// BYTE stream

struct FileHeader {
	BYTE	signature[32];
	DWORD	version;
	DWORD	property;
	BYTE	reserved[216];
};

#define HWPTAG_BEGIN 0x010

/* DocInfo */
#define HWPTAG_DOCUMENT_PROPERTIES	(HWPTAG_BEGIN)
#define HWPTAG_ID_MAPPINGS			(HWPTAG_BEGIN+1)
#define HWPTAG_BIN_DATA				(HWPTAG_BEGIN+2)
#define HWPTAG_FACE_NAME			(HWPTAG_BEGIN+3)
#define HWPTAG_BORDER_FILL			(HWPTAG_BEGIN+4)
#define HWPTAG_CHAR_SHAPE			(HWPTAG_BEGIN+5)
#define HWPTAG_TAB_DEF				(HWPTAG_BEGIN+6)
#define HWPTAG_NUMBERING			(HWPTAG_BEGIN+7)
#define HWPTAG_BULLET				(HWPTAG_BEGIN+8)
#define HWPTAG_PARA_SHAPE			(HWPTAG_BEGIN+9)
#define HWPTAG_STYLE				(HWPTAG_BEGIN+10)
#define HWPTAG_DOC_DATA				(HWPTAG_BEGIN+11)
#define HWPTAG_DISTRIBUTE_DOC_DATA	(HWPTAG_BEGIN+12)
#define RESERVED					(HWPTAG_BEGIN+13)
#define HWPTAG_COMPATIBLE_DOCUMENT	(HWPTAG_BEGIN+14)
#define HWPTAG_LAYOUT_COMPATIBILITY	(HWPTAG_BEGIN+15)

#define HWPTAG_FORBIDDEN_CHAR		(HWPTAG_BEGIN+78)

struct DOCUMENT_PROPERTIES {
	UINT16	section_count; /* 구역 개수 */
	/* 문서 내 각종 시작번호에 대한 정보 */
	UINT16	start_num_of_page;
	UINT16	start_num_of_footnote; /* 각주 */
	UINT16	start_num_of_headnote; /* 미주 */
	UINT16	start_num_of_picture;
	UINT16	start_num_of_table;
	UINT16	start_num_of_fomula;
	/* 문서 내 캐럿의 위치 정보 */
	UINT32	list_id;
	UINT32	para_id;
	UINT32	pos_char_in_para;
};

/* 레코드 */
typedef struct {
// typedef unsigned long DWORD;    // 4 Bytes
	DWORD tag_id	:10;
	DWORD level		:10;
	DWORD size		:12;
} Header;

typedef struct {
	int *record_data;
} Data;

typedef struct {
	Header	*header;
	Data	*data;
} Record;

/* Section */
int test()
{
	Record record;
	Header header;
	Data   data;

	record.header = &header;
	record.data   = &data;

/*
	header = read(4)

	if header.tag_id == HWPTAG_DOCUMENT_PROPERTIES {
		DOCUMENT_PROPERTIES document_properties;
	}

	if header.level == ?? {
	}

	if header.size != 0 {
		record.data = malloc(header.size);
	}

	header.level
	header.size
*/
	return sizeof(record);
}
