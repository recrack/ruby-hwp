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
#include "libhwp.h"

#define HWPTAG_BEGIN 0x010
#define HWPTAG_ID_MAPPINGS (HWPTAG_BEGIN + 100)

int main(int argc, char* argv[]) {
	printf("%d", sizeof(test()));
	return 0;
}
