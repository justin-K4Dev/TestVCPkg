// main.cpp : 이 파일에는 'main' 함수가 포함됩니다. 거기서 프로그램 실행이 시작되고 종료됩니다.
//

#include "stdafx.h"

#include "Function.h"


int _tmain(int argc, _TCHAR* argv[])
{
	BoostLogic::Test();
	CurlLogic::Test();
	OpenSSLLogic::Test();
	ZipLogic::Test();

	return 0;
}

