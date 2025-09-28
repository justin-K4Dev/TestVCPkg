# vcpkg 개요 & 주요 설치 가이드


## 1. vcpkg 란?
  - C/C++ 개발을 위한 Microsoft의 오픈소스 패키지 관리 도구
  - 라이브러리 설치/제거/업데이트/프로젝트 통합 기능을 제공하고,
    Windows, Linux, macOS 에서 사용 가능하다.


---


## 2. OS 및 IDE별 지원 버전
  - Windows
    - Windows 7 SP1, 8.1, 10, 11 이상에서 동작
    - Windows Server 2012 이상도 지원
    - 32비트, 64비트 모두 사용 가능 (64비트 권장)
  - Linux
    - 주요 리눅스 배포판(Ubuntu, Debian, CentOS, Fedora 등) 대부분 지원
    - 최소 C++17 컴파일러(GCC 7 이상) 필요
  - macOS
    - macOS 10.13(High Sierra) 이상 권장
    - Xcode 및 최신 Command Line Tools 필요
    - 최소 C++17 지원 컴파일러(Clang 9.0 이상) 필요

  - IDE 지원
    - Visual Studio 2015, 2017, 2019, 2022  
      - 2017 15.3 이상에서 vcpkg 통합(integrate) 공식 지원
      - Visual Studio 2019, 2022에서 매니페스트 모드(프로젝트별 vcpkg.json) 완벽 지원
    - Visual Studio Code(Any)에서는 CMake Tools 확장, 터미널 등에서 사용 가능

  - CMake 및 컴파일러
    - CMake 3.14 이상 권장, 매니페스트 모드는 CMake 3.21 이상 권장
    - 컴파일러: GCC 7+, Clang 9+, MSVC 2017+ 필요 (C++17 이상 지원 필수)
    - 대부분의 패키지가 C++17을 요구하므로, 최신 컴파일러일수록 호환성이 좋음


---


## 3. vcpkg 주요 속성 정의 및 활용

### vcpkg 주요 속성 정의
  - $schema : JSON이 어떤 “형식 규칙(JSON Schema)”을 따르는지를 가리키는 표준 키
  ```json
    "$schema": "https://raw.githubusercontent.com/microsoft/vcpkg-tool/main/docs/vcpkg-configuration.schema.json"
  ```
  - name : 식별명; 소문자 a–z, 숫자, 하이픈(-)만 사용; 앞뒤 하이픈, 언더스코어, 공백, 대문자 금지 (예: "my-project", "my-port", "my-libs")
  - version : 완화된 SemVer(점으로 구분된 숫자 갯수 자유) (예: 1.2.3.4, 10.0.1-alpha1)
  - version>= : 최소 버전 (예: "1.2.3", "1.2.3#1" <- port-version 과 조합(#port-version))
  - version-semver : 엄격한 SemVer 2.0.0 (예: 2.0.1-rc5)
  - version-date : 날짜형 (예: 2024-09-01.2 (Live-at-HEAD 등))
  - version-string : 임의 문자열 버전(정렬 안 함); 같은 문자열일 때만 port-version으로 세부 비교 (특수한 경우에만 사용 권장) (예: "rev-2025-09-01-gabc123")
  - dependencies : 설치할 패키지 관련 속성 목록
    - name : 패키지 식별명 (예: "openssl")
    - features : 해당 패키지의 선택 기능 (예: ["core"], ["tools", "secure-memory"] )
    - default-features : 기본 패키지 on/off (예: false, true)
    - platform : 의존하는 플랫폼 (예: "windows & x64", "!uwp & (windows | linux) & x64" <- !:부정의미)
    - host : 빌드 중 실행될 도구(코드 생성기 등)를 ‘호스트 트리플릿’로 설치 (빌드 툴·코드생성기 등) (예: true, false)
    - port-version : 포트 재포장 버전, 소스 버전 그대로, 포트만 바뀔 때 증가, 0 이상 사용 (예: 0)
  - builtin-baseline : 매니페스트 모드에서 builtin 레지스트리의 기준 커밋을 고정(버전 스냅샷); 재현성 확보를 위해 권장 (예: "6ecbbbdf31cba47aafa7cf6189b1e73e10ac61f8")
  - baseline : git 레지스트리를 명시할 때 그 레지스트리의 버전 기준을 고정 (예: "6ecbbbdf31cba47aafa7cf6189b1e73e10ac61f8")
  - description : 설명 텍스트, 노출 정보용 메타 데이터 (예: "Live-at-HEAD style package with non-orderable version"
  - homepage : 링크 URL (예: "https://example.com/my-lib")
  - license : 라이선스 식별자/텍스트 (예: "MIT")
  - supports : 포트(또는 피처)가 빌드 가능한 플랫폼 (예: "windows & x64 & static", "!uwp", "windows | linux")
  - features : 포트가 제공하는 선택적 구성요소를 정의 
  ```json
	"features" : [
        "ssl": {
            "description": "Enable OpenSSL support",
            "dependencies": ["openssl"],        // 이 피처가 켜지면 openssl도 설치
            "supports": "windows | linux"       // (선택) 제공 플랫폼 제한
        },
    ]
  ```
  - overrides : 특정 패키지의 버전을 강제 고정할 패키지 속성 목록 (레지스트리의 버전 해석을 덮어씀)
  ```json
	"overrides" : [
    	{ "name": "zlib",    "version": "1.2.12" },
    	{ "name": "fmt",     "version-semver": "9.1.0" },
    	{ "name": "openssl", "version": "3.0.9", "port-version": 2 }
    ]
  ```
  - default-registry : 기본 레지스트리 설정 (예: kind 예제 참조)
  - registries : **사설 레지스트리 설정** (예: kind 예제 참조)
  - repository : 레지스트리의 **Git 저장소 주소(HTTPS/SSH)**; kind: "git" 에서만 사용
  - path : 로컬(또는 네트워크) 디스크에 있는 **사설 vcpkg 레지스트리 폴더**의 루트 경로; kind: "filesystem" 에서만 사용
  - reference : Git 레지스트리에서 **어느 브랜치/태그를 기준으로 버전 목록을 읽을지** 지정하는 선택; 생략 시 HEAD
  - packages : 레지스트리에서 **어떤 포트 이름(패턴)** 매핑 규칙을 문자열 배열로 설정 (예: ["myorg-*", "internal-*"])
  - kind : **레지스트리의 유형을 지정하는 필드**; 종류("git", "filesystem", "builtin")
    - "git" : Git 레지스트리
      - 필요: repository(URL/경로), baseline(40자리 커밋 SHA), (선택) reference(브랜치/태그)
      ```json
      	"default-registry": {
      		"kind": "git",
      		"repository": "https://git.example.com/mirrors/vcpkg.git",
      		"baseline": "84a143e4caf6b70db57f28d04c41df4a85c480fa",
      		"reference": "release/2025Q1"
      	}
      ```
    - "filesystem" : 로컬/네트워크 폴더 레지스트리
      - 필요: path(폴더 경로), packages(패턴)
      ```json
      	"registries": [
      		{
      			"kind": "filesystem",
      			"path": "./my-registry",
      			"baseline": "default",
      			"packages": ["myorg-*"]
      		}
      	]
      ```
    - "builtin" : vcpkg 기본(공식) 레지스트리
      - 필요: baseline(공식 레포의 커밋 SHA)
      ```json
      	"default-registry": {
      	    "kind": "builtin",
      	    "baseline": "eefee7408133f3a0fef711ef9c6a3677b7e06fd7",
      	}
      ```
  - overlay-ports
    - vcpkg가 포트를 찾을 때, 기본 레지스트리보다 먼저 조회하는 추가 검색 경로 목록
    - 여기 있는 포트 이름과 같은 이름의 공식 포트가 있어도 오버레이 쪽이 우선 적용되어 대체(override)
    - 오버레이 포트 n개 : vcpkg-configuration.json
    ```json
        "$schema": "https://raw.githubusercontent.com/microsoft/vcpkg-tool/main/docs/vcpkg-configuration.schema.json",	
        "overlay-ports": [
    	    "./ports",
    	    "C:\\src\\shared-ports",
    	    "\\\\fileserver\\vcpkg\\team-ports"
        ]
    ```
    - vcpkg.json 내부에 설정
    ```json
    	"name": "my-app",
    	"version": "0.0.1",
    	"builtin-baseline": "abcdef1234567890abcdef1234567890abcdef12",
    	"dependencies": ["openssl", "zlib"],
    	"vcpkg-configuration": {
    		"overlay-ports": ["./ports"]
    	}
    ```
  - overlay-triplets :
    - vcpkg가 트리플릿(triplet) 파일을 찾을 때, 기본 트리플릿 폴더보다 먼저 확인하는 추가 검색 경로 목록
      - 오버레이 트리플릿n개 : vcpkg-configuration.json
    ```json
        "$schema": "https://raw.githubusercontent.com/microsoft/vcpkg-tool/main/docs/vcpkg-configuration.schema.json",
        "overlay-triplets": [
    	    "./triplets",
    	    "C:\\company\\vcpkg\\triplets"
        ]
    ```
    - vcpkg.json 내부에 설정
    ```json
    	"name": "my-app",
    	"version": "0.0.1",
    	"builtin-baseline": "abcdef1234567890abcdef1234567890abcdef12",
    	"dependencies": ["openssl", "zlib"],
    	"vcpkg-configuration": {
    		"overlay-triplets": ["./triplets"]
    	}
    ```

### vcpkg.json 개요
  - 프로젝트(또는 포트)의 의존성·버전 요구사항을 선언하는 파일
  - 이 파일이 있는 디렉터리에서 vcpkg install을 실행하면 매니페스트 모드로 동작하고,
    "dependencies"에 적힌 패키지를 설치 한다.
  - 동일 파일을 포트(overlay 포함) 안에 둘 때는, 그 포트의 메타데이터(이름/버전/라이선스 등) 역할을 한다.
  ```json
	"name": "my-project" 또는 "zlib",
	"version": "0.0.1",
	"builtin-baseline": "abcdef1234567890...",
	"dependencies": [
		"zlib",
		{ "name": "openssl", "features": ["tools"], "default-features": false },
		{ "name": "protobuf", "host": true }
	]
  ```

### vcpkg-configuration.json 개요
  - vcpkg가 포트를 어디서/어떤 스냅샷으로 찾을지 결정(레지스트리, 오버레이, 트리플릿 경로)
  - 프로젝트 루트(권장) 또는 vcpkg 루트에 두거나, vcpkg.json 안에 **"vcpkg-configuration": { ... }**로 임베드 가능
  - 매니페스트/클래식 공통: 레지스트리, 오버레이 해석에 모두 적용
  - vcpkg-configuration.json 설정의 예
  ```json
	"default-registry": {
		"kind": "builtin",
		"baseline": "eefee7408133f3a0fef711ef9c6a3677b7e06fd7"
	},
	"registries": [
		{
			"kind": "git",
			"repository": "https://git.example.com/infra/vcpkg-registry.git",
			"reference": "main",
			"baseline": "112233aabbccddeeff00112233445566778899aa",
			"packages": ["myorg-*"]
		}
	],
	"overlay-ports": ["./ports"],
	"overlay-triplets": ["./triplets"]
  ```
  - vcpkg.json 내부에 설정
  ```json
	"name": "my-app",
    "builtin-baseline": "abcdef1234567890...",
    "dependencies": ["zlib", "myorg-core"],
    "vcpkg-configuration": {
		"overlay-ports": ["./ports"],
		"overlay-triplets": ["./triplets"],	
		"registries": [
			{
				"kind": "git",
				"repository": "https://git.example.com/infra/vcpkg-registry.git",
				"baseline": "112233aabbccddeeff00112233445566778899aa",
				"packages": ["myorg-*"]
			}
		]
    }
  ```

---


## 4. 주요 개념 정리

### 포트 (Port)
  - 하나의 라이브러리(또는 툴)를 **어떻게 가져와 빌드·설치**할지 정의한 **패키지 레시피**
  - 포트 폴더 스켈레톤 (Port Folder Skeleton) 구성
    - 구성: `vcpkg.json`(메타/버전/의존성/피처) + `portfile.cmake`(빌드·설치 스크립트)
    - 선택: `patches/`, `cmake/*`, `usage`, `src/*`(로컬 번들 소스) 등
  - **커스텀 포트** 가능 => 오버레이 포트(Overlay Ports)

#### 포트 폴더 스켈레톤 (Port Folder Skeleton)
  - vcpkg에서 *하나의 포트(Port)*가 동작하는 데 필요한 최소 디렉터리/파일 구성 템플릿
  - 해당 라이브러리를 어떻게 빌드/설치할지 내용들이 담겨짐
  ```markdown
  ports/<port-name>/
   ├─ vcpkg.json            		← 포트 메타데이터(버전/의존성/피처/라이선스 등)
   ├─ portfile.cmake        		← 실제 빌드/설치 스크립트
   ├─ patches/              		← (선택) 소스 패치들 *.patch
   ├─ cmake/                		← (선택) 보조 CMake 스크립트
   ├─ vcpkg-cmake-wrapper.cmake     ← (선택) find_package 개선용 래퍼
   └─ usage                 		← (선택) 설치 후 안내 문구
  ```

### 트리플릿 (Triplet)
  - **플랫폼 + 라이브러리 링크 방식 + CRT 정책** 조합의 이름
  - 예: `x64-windows`, `x64-windows-static`, `x64-linux`, `arm64-osx`
  - **커스텀 트리플릿** 가능 => 오버레이 트리플릿(Overlay Triplets)

### Baseline & Registries
  - **baseline**: vcpkg 포트 인덱스의 **스냅샷 커밋(SHA)** → **버전 재현성**의 기준
  - **registries**: 기본(builtin) 외 **사설/추가 레지스트리** 등록 → 포트 해석을 분기

### 오버레이 (Overlay)
  - **overlay-ports**: 공식 포트보다 **내 포트 레시피**를 **우선 적용**(커스텀/패치/사내용 포트)
  - **overlay-triplets**: 기본 트리플릿 대신 **내 빌드 정책**(정적/동적/CRT/툴체인) 사용

### 바이너리 캐시 (Binary Cache)
  - **빌드 산출물 재사용**으로 CI 속도 개선 (`VCPKG_DEFAULT_BINARY_CACHE`)


---


## 5. vcpkg 설치

### PowerShell 설치 (선택)
  - WinGet을 이용한 설치
  ```powershell
  winget search Microsoft.PowerShell

  Name               Id                           Version Source
  ---------------------------------------------------------------
  PowerShell         Microsoft.PowerShell         7.5.3.0 winget
  PowerShell Preview Microsoft.PowerShell.Preview 7.6.0.4 winget

  winget install --id Microsoft.PowerShell --source winget
  ```
  - MSI Package를 이용한 설치
    - Download URL : https://github.com/PowerShell/PowerShell/releases/download/v7.5.3/PowerShell-7.5.3-win-x64.msi
    - PowerShell-7.5.3-win-x64.msi 파일 실행

### Git 설치
  - https://git-scm.com 에서 Git 설치

### vcpkg Source Clone
  - 명령 프롬프트(또는 터미널)에서 원하는 폴더로 이동 후:
    git clone https://github.com/microsoft/vcpkg.git

### vcpkg Bootstrap 실행
  - Windows : PowerShell
  ```powershell
  git clone https://github.com/microsoft/vcpkg.git C:\Tools\vcpkg
  C:\Tools\vcpkg\bootstrap-vcpkg.bat
  ```
  - Linux / macOS : Bash
  ```bash
  git clone https://github.com/microsoft/vcpkg.git ~/vcpkg
  ~/vcpkg/bootstrap-vcpkg.sh
  ```
  > Tip: 가끔 git pull 후 bootstrap을 다시 실행해 최신 기능을 반영한다.

### PATH 환경변수 등록 (선택) 
  - vcpkg.exe가 포함된 폴더(예: C:\dev\vcpkg)를 PATH에 추가하면 명령어를 어디서나 쓸 수 있다.


---


## 6. vcpkg & Visual Studio 프로젝트 연동

### Visual Studio C++ 설치
  - IDE 지원 참조

### Visual Studio C++ 통합 (최초 1회)
  - vcpkg integrate install
  ```powershell
  vcpkg integrate install
  ```
  - 이 과정으로 $(VcpkgIncludePath)가 VS 프로젝트내에 자동 설정 !!!
  - 경로 참조 순서를 임의로 설정할 경우
    + 프로젝트 속성에서 추가 포함 디렉터리내에서 순서 조정
      예) $(ProjectDir)MyIncludes;$(VcpkgIncludePath);C:\OtherLib\include

  - 통합 후에는 #include <라이브러리헤더> 로 바로 사용 가능
  - Visual Studio에서 추가 포함 디렉터리/라이브러리 경로 자동 등록 !!!

### Visual Studio C++ 통합 해제
  - vcpkg integrate remove
  ```powershell
  vcpkg integrate remove
  ```

---


## 7. 패키지 관리 (조회, 설치, 제거, 버전 변경)

### 모든 명령어 및 사용법 안내 
  - vcpkg help
  ```
  vcpkg help
  ```

### 설치된 모든 포트 목록 조회
  - vcpkg list
  ```
  vcpkg list
  ```

### Ports 목록에 특정 Port 조회
  - 설치 가능한 “포트(Port)” 목록에서 키워드로 조회
  - vcpkg search <포트명>
  ```
  vcpkg search boost
  ```

### 특정 포트의 버전 목록 조회 
  - 해당 포트의 “공식 레지스트리(versions DB)”에 기록된 모든 버전 이력을 조회
  - vcpkg x-history <포트명>
  ```
  vcpkg x-history zlib

  version: 11.0.2, port-version: 0, git-tree: 3f1a2b...
  version: 11.0.1, port-version: 1, git-tree: 7ac9d0...
  version: 11.0.1, port-version: 0, git-tree: 51e4f2...
  version: 10.2.1, port-version: 3, git-tree: a8b77c...
  ```

### 패키지 설치 (Package Install)
  - Classic & Manifest 모드로 구분하여 설치할 수 있다.

##### Classic 설치
  - vcpkg install <포트명>[:triplet]
  ```
  vcpkg install fmt      (자동)
  vcpkg install fmt:x64-windows or fmt:x86-windows
  vcpkg install boost:x64-linux
  ```
  - Command Line에 패키지명을 입력하는 경우 Classic 모드로 설치 된다.
  - 패키지 설치 경로: 설치된 vcpkg 경로의 root\installed\<triplet>\include, lib, bin 등
  - 디렉토리 구성
  ```markdown
	vcpkg-root/
	├─ vcpkg.exe
	├─ vcpkg-configuration.json       	← (여기서 vcpkg CLI를 실행할 때 읽힘)
	├─ installed/						← 패키지 설치 기본 경로
	└─ ...
  ```

##### Manifest 설치
  - vcpkg install --triplet <트리플릿명>
  ```
  cd C:\src\myapp
  vcpkg install --triplet x64-windows
  ```
  - vcpkg install --x-manifest-root=<프로젝트루트경로> --x-install-root=<라이브러리설치루트경로> ^
         --triplet <트리플릿명>
  ```
  vcpkg install --x-manifest-root=C:\src\my-project --x-install-root="C:\src\my-project\vcpkg_installed" ^
                --triplet x64-windows
  ```
  - Manifest의 루트 디렉터리의 vcpkg.json을 읽어 의존성을 설치 한다.
  ```json
  {
  	"name": "my-project",
  	"version": "0.0.1",
  	"dependencies": [ "fmt" ]
  }
  ```
  - Command Line에 패키지명을 입력하는 경우 Classic 모드로 설치 된다.
  - 패키지 설치 경로: 설치된 프로젝트 루트 경로의 project_root\vcpkg_installed\<triplet>\include, lib, bin 등
  - 디렉토리 구성
  ```markdown
    my-project/	
  	├─ vcpkg.json
  	├─ vcpkg-configuraion.json
	├─ vcpkg_installed/					← 패키지가 설치될 경로
  	└─ ...
  ```

##### Overlay Ports & Triplets 사용
  - vcpkg install --x-manifest-root=. --triplet x64-windows ^
                  --overlay-ports=<재정의포트경로> --overlay-triplets=<재정의트리플릿경로>
  ```powershell
  vcpkg install --x-manifest-root="C:\src\my-project" --x-install-root="C:\src\my-project\vcpkg_installed" ^
				--triplet x64-windows-static-mt ^
				--overlay-ports=C:\src\my-project\overlays\ports ^
				--overlay-triplets=C:\src\my-project\overlays\triplets
  ```
  - 디렉토리 구성
  ```markdown
    my-project/
  	├─ vcpkg.json
  	├─ vcpkg-configuraion.json
  	├─ CMakeLists.txt
	├─ vcpkg_installed/						← 패키지가 설치될 경로
  	├─ overlays
	│  ├─ ports/
  	│  │   └─ zlib/              			← 포트 폴더 스켈레톤
  	│  │      ├─ vcpkg.json
  	│  │      ├─ portfile.cmake
    │  │      └─ ...
  	│  └─ triplets
	│     ├─ x64-windows-static-mt.cmake	← (Windows 전용 샘플)
  	│     └─ x64-linux-static.cmake     	← (Linux 전용 샘플)
  	└─ ...
  ```

##### Overlay Ports 설정
  - my-project/overlays/ports/zlib/vcpkg.json
  ```json
	"name": "zlib",
	"version": "1.3.1-overlay1",
	"homepage": "https://zlib.net/",
	"description": "A compression library (overlay port)",
	"license": "Zlib",
	"dependencies": [
		{
			"name": "vcpkg-cmake",
			"host": true
		},
		{
			"name": "vcpkg-cmake-config",
			"host": true
		}
	]
  ```
  - my-project/overlays/ports/zlib/vcpkg-configuraion.json
  ```json
	"$schema": "https://raw.githubusercontent.com/microsoft/vcpkg-tool/main/docs/vcpkg-configuration.schema.json",
	"binaryCache": {
		"kind": "files",
		"path": "vcpkg-BinaryCache"
	},

	"overlays-ports": [
		"overlays/ports"
	],
	"overlay-triplets": [
		"overlays/triplets"
	]
  ```

  - my-project\overlays\ports\zlib\profile.cmake	
  ```cmake
  # -----------------------------------------------------------------------------------------
  # zlib overlay portfile.cmake
  # -----------------------------------------------------------------------------------------

  # 사용할 tag/commit
  # set(ZLIB_REF "v1.3.1")
  # 특정 커밋 고정 시:
  set(ZLIB_REF "51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf")

  # 1) git에서 소스 가져오기 (URL 을 사용해야 함)
  vcpkg_from_git(
  	OUT_SOURCE_PATH SOURCE_PATH
  	URL https://github.com/madler/zlib.git
  	REF ${ZLIB_REF}
  )

  # 2) 표준 CMake configure/build/install
  vcpkg_cmake_configure(
  	SOURCE_PATH "${SOURCE_PATH}"
  	OPTIONS
  		-DCMAKE_RC_COMPILER=rc
  		-DCMAKE_MT=mt
  )
  vcpkg_cmake_build()
  vcpkg_cmake_install()

  # -----------------------------------------------------------------------------------------
  # post-install 정리
  # -----------------------------------------------------------------------------------------

  # upstream cmake config 잔여물 제거(혼선 방지)
  file(REMOVE_RECURSE
  	"${CURRENT_PACKAGES_DIR}/lib/cmake"
  	"${CURRENT_PACKAGES_DIR}/debug/lib/cmake")

  # static 빌드에서 동적 산출물/빈 디렉토리 제거
  if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
  	file(REMOVE_RECURSE
  		"${CURRENT_PACKAGES_DIR}/bin"
  		"${CURRENT_PACKAGES_DIR}/debug/bin")
  endif()

  # 2) pkgconfig 이동 + 고정
  # upstream은 share/pkgconfig/zlib.pc에 놓는 경우가 있어 pkgconf 탐색 규칙에 맞게 이동
  if(EXISTS "${CURRENT_PACKAGES_DIR}/share/pkgconfig/zlib.pc")
  	file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/lib/pkgconfig")
  	file(RENAME
  		"${CURRENT_PACKAGES_DIR}/share/pkgconfig/zlib.pc"
  		"${CURRENT_PACKAGES_DIR}/lib/pkgconfig/zlib.pc")
  endif()
  if(EXISTS "${CURRENT_PACKAGES_DIR}/debug/share/pkgconfig/zlib.pc")
  	file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig")
  	file(RENAME
  		"${CURRENT_PACKAGES_DIR}/debug/share/pkgconfig/zlib.pc"
  		"${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/zlib.pc")
  endif()

  # 남은 share/pkgconfig 잔여 정리
  file(REMOVE_RECURSE
  	"${CURRENT_PACKAGES_DIR}/debug/include"
  	"${CURRENT_PACKAGES_DIR}/debug/share"
  	"${CURRENT_PACKAGES_DIR}/debug/share/zlib")

  # .pc 내부 prefix/경로 정규화
  vcpkg_fixup_pkgconfig()

  # 3) debug/include, debug/share 정리(헤더 중복 제거)
  file(REMOVE_RECURSE
  	"${CURRENT_PACKAGES_DIR}/debug/include"
  	"${CURRENT_PACKAGES_DIR}/debug/share")

  vcpkg_test_cmake(PACKAGE_NAME ZLIB CONFIG TARGETS ZLIB::ZLIB)

  # 4) PDB 복사(있으면)
  vcpkg_copy_pdbs()

  # -----------------------------------------------------------------------------------------
  # CONFIG 모드용 얇은 ZLIBConfig.cmake 생성
  #  - zlib.lib | zlibstatic.lib (Release)
  #  - zlibd.lib | zlibstaticd.lib (Debug)
  # -----------------------------------------------------------------------------------------
  file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/share/zlib")

  file(WRITE "${CURRENT_PACKAGES_DIR}/share/zlib/ZLIBConfig.cmake" [=[
  # Minimal ZLIBConfig.cmake generated by overlay (zlib.lib / zlibd.lib aware)
  include_guard(GLOBAL)

  # <pkg>/share/zlib/ZLIBConfig.cmake -> <pkg>
  get_filename_component(PACKAGE_PREFIX_DIR "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)

  set(_inc_dir "${PACKAGE_PREFIX_DIR}/include")

  set(_lib_rel_candidates
  	"${PACKAGE_PREFIX_DIR}/lib/zlib.lib"
  	"${PACKAGE_PREFIX_DIR}/lib/zlibstatic.lib"
  )
  set(_lib_dbg_candidates
  	"${PACKAGE_PREFIX_DIR}/debug/lib/zlibd.lib"
  	"${PACKAGE_PREFIX_DIR}/debug/lib/zlibstaticd.lib"
  )

  set(_lib_rel "")
  foreach(_cand IN LISTS _lib_rel_candidates)
  	if(EXISTS "${_cand}")
  		set(_lib_rel "${_cand}")
  		break()
  	endif()
  endforeach()

  set(_lib_dbg "")
  foreach(_cand IN LISTS _lib_dbg_candidates)
  	if(EXISTS "${_cand}")
  		set(_lib_dbg "${_cand}")
  		break()
  	endif()
  endforeach()

  if(NOT _lib_rel AND NOT _lib_dbg)
  	message(FATAL_ERROR
  	  "Neither zlib.lib nor zlibd.lib was found under ${PACKAGE_PREFIX_DIR}.")
  endif()

  if(NOT TARGET ZLIB::ZLIB)
  	add_library(ZLIB::ZLIB STATIC IMPORTED)

  	if(_lib_rel AND _lib_dbg)
  		set_property(TARGET ZLIB::ZLIB PROPERTY IMPORTED_CONFIGURATIONS "RELEASE;DEBUG")
  		set_property(TARGET ZLIB::ZLIB PROPERTY IMPORTED_LOCATION_RELEASE "${_lib_rel}")
  		set_property(TARGET ZLIB::ZLIB PROPERTY IMPORTED_LOCATION_DEBUG   "${_lib_dbg}")
  	elseif(_lib_rel)
  		# 단일 구성(Release만) 혹은 멀티 구성의 기본값 대응
  		set_property(TARGET ZLIB::ZLIB PROPERTY IMPORTED_LOCATION "${_lib_rel}")
  	else()
  		# Debug만 있는 특수 상황 대응
  		set_property(TARGET ZLIB::ZLIB PROPERTY IMPORTED_CONFIGURATIONS "DEBUG")
  		set_property(TARGET ZLIB::ZLIB PROPERTY IMPORTED_LOCATION_DEBUG "${_lib_dbg}")
  		set_property(TARGET ZLIB::ZLIB PROPERTY IMPORTED_LOCATION        "${_lib_dbg}")
  	endif()

  	target_include_directories(ZLIB::ZLIB INTERFACE "${_inc_dir}")
  endif()
  ]=])

  # 사용법 안내
  file(WRITE "${CURRENT_PACKAGES_DIR}/share/zlib/usage" [=[
  Use config mode:

  	find_package(ZLIB CONFIG REQUIRED)
  	target_link_libraries(your_app PRIVATE ZLIB::ZLIB)
  ]=])

  # -----------------------------------------------------------------------------------------
  # 라이선스 설치
  # -----------------------------------------------------------------------------------------
  file(GLOB _copyright
  	 LIST_DIRECTORIES false
  	 "${SOURCE_PATH}/README"
  	 "${SOURCE_PATH}/README.md")

  if(NOT _copyright)
  	message(WARNING "No README/README.md found in ${SOURCE_PATH} for copyright install.")
  else()
  	vcpkg_install_copyright(FILE_LIST ${_copyright})
  endif()
  ```

##### Overlay Triplet 설정
  - my-project\overlays\triplets\x64-windows-static-mt.cmake
  ```cmake
  set(VCPKG_TARGET_ARCHITECTURE x64)
  set(VCPKG_CMAKE_SYSTEM_NAME Windows)
  set(VCPKG_CRT_LINKAGE static)   # /MT
  set(VCPKG_LIBRARY_LINKAGE static)
  ```

##### 매니페스트 프로젝트 설정
  - my-project\vcpkg.json
  ```json
	"$schema": "https://raw.githubusercontent.com/microsoft/vcpkg-tool/main/docs/vcpkg.schema.json",
	"name": "manifest-overlay",
	"version-string": "0.0.1",
	"dependencies": [
		"zlib"
	],
	"builtin-baseline": "6ecbbbdf31cba47aafa7cf6189b1e73e10ac61f8"
  ```
  - my-project\vcpkg-configuraion.json
  ```json
	"$schema": "https://raw.githubusercontent.com/microsoft/vcpkg-tool/main/docs/vcpkg-configuration.schema.json",
	"binaryCache": {
		"kind": "files",
		"path": "vcpkg-BinaryCache"
	},

	"overlay-ports": [
		"overlays/ports"
	],

	"overlay-triplets": [
		"overlays/triplets"
	]
  ```

##### 프로젝트 빌드 코드 생성용 CMake 작성
  - my-project\CMakeLists.txt
  ```cmake
  cmake_minimum_required(VERSION 3.20)
  project(AppWithVcpkgZlib NONE)

  option(VERIFY_ZLIB "Verify that vcpkg-provided ZLIB is findable" OFF)

  if(VERIFY_ZLIB)
  	# vcpkg의 CONFIG 모드 사용 권장
  	find_package(ZLIB CONFIG QUIET)
  	if(NOT ZLIB_FOUND OR NOT TARGET ZLIB::ZLIB)
  		message(FATAL_ERROR "ZLIB not found (or no target ZLIB::ZLIB). Check manifest/overlay/triplet.")
  	endif()

  	# 임포트 타깃의 디버그/릴리스 경로 출력
  	get_target_property(_cfgs ZLIB::ZLIB IMPORTED_CONFIGURATIONS)
  	if(NOT _cfgs)
  		# 단일 구성만 있을 수 있음(예: IMPORTED_LOCATION만 설정된 경우)
  		get_target_property(_loc ZLIB::ZLIB IMPORTED_LOCATION)
  		message(STATUS "ZLIB::ZLIB imported (single-config). LOCATION=${_loc}")
  	else()
  		foreach(_c IN LISTS _cfgs)
  			string(TOUPPER "${_c}" _C)
  			get_target_property(_loc ZLIB::ZLIB "IMPORTED_LOCATION_${_C}")
  		message(STATUS "ZLIB::ZLIB imported (${_c}) LOCATION=${_loc}")
  		endforeach()
  	endif()

  	get_target_property(_incs ZLIB::ZLIB INTERFACE_INCLUDE_DIRECTORIES)
  	message(STATUS "ZLIB include dirs: ${_incs}")
  endif()
  ```

##### CMake 실행
	​```
	cd C:\src\my-project\app
	cmake -S . -B build ^
	  -DCMAKE_TOOLCHAIN_FILE=C:\vcpkg\scripts\buildsystems\vcpkg.cmake ^
	  -DVCPKG_TARGET_TRIPLET=x64-windows-static-mt ^
	  -DCMAKE_BUILD_TYPE=Release
	cmake --build build --config Release
	​```

##### CMake 연동
  - vcpkg는 패키지를 설치할 때 내부적으로 CMake(또는 Meson/Autotools 등)를 호출 한다.
  - Manifest : 프로젝트 루트 디렉토리의 vcpkg.json에 의존성 선언 → 자동 복원/설치
  - 해당 Port를 위해 CMake Helper 스크립트를 사용할 수 있다. (예: vcpkg_cmake_configure ...)
    - 해당 포트의 vcpkg.json 에 아래의 내용 설정 필요
    ```json
    {
    	"name": "zlib",
    	"version": "1.3.1-overlay1",
    	"homepage": "https://zlib.net/",
    	"description": "A compression library (overlay port)",
    	"license": "Zlib",
    	"dependencies": [
    		{
    			"name": "vcpkg-cmake",
    			"host": true
    		},
    		{
    			"name": "vcpkg-cmake-config",
    			"host": true
    		}
    	]
    }
    ```
  - 해당 Port를 위해 CMake에 옵션을 전달하려면 환경변수를 이용해도 된다.
  ```powershell
  $env:VCPKG_CMAKE_GENERATOR = "Visual Studio 17 2022"
  $env:VCPKG_CMAKE_GENERATOR_PLATFORM = "x64"
  $env:VCPKG_CMAKE_GENERATOR_TOOLSET = "v143,version=14.44.35207"
  ```
  ```cmake
  # 해당 Port의 Triplet cmake
  set(VCPKG_CMAKE_GENERATOR "Visual Studio 17 2022")
  set(VCPKG_CMAKE_GENERATOR_PLATFORM "x64")   # x64
  set(VCPKG_CMAKE_GENERATOR_TOOLSET "v143,version=14.44.35207")   # v143 (선택)
  ```
  ```powershell
  vcpkg install zlib:x64-windows-static
  ```

### Port 버전 변경 (Port Version Change)
  - 변경 대상 Port의 버전을 변경 한다.  
  - Port 버전은 두 방식을 변경할 수 있다.
    - Classic 모드
      - vcpkg 저장소 자체의 포트 트리(commit)를 바꿔서(또는 오버레이 포트로) 원하는 버전을 사용
	  - vcpkg update & upgrade 명령어 사용 가능
    - Manifest 모드
      - vcpkg.json에 버전 제약/오버라이드 + builtin-baseline을 명시해서, 프로젝트 단위로 버전을 고정
	  - vcpkg update & upgrade 명령어 사용 불가 !!!
	  - vcpkg insert 또는 remove 후에 insert 명령어를 활용

#### Classic 모드
  - vcpkg-root 경로내에 전역적인 범위로 관리

##### 포트 트리(Port Tree)로 전환 (모든 포트에 영향)

  - 1. 삭제 후 설치 하기
    - 특정 Port 버전이 포함된 설정된 저장소의 Commit SHA512를 변경하여 해당 포트의 버전을 변경
    ```powershell
	  # 1) 원하는 버전의 커밋 찾기
	  vcpkg x-history fmt   # 사용 가능한 버전/커밋 로그 확인

	  # 2) vcpkg 저장소를 그 커밋으로 이동
	  git -C E:\Library\vcpkg checkout 6ecbbbdf31cba47aafa7cf6189b1e73e10ac61f8

	  # 3) 재설치(필요시 제거 후 설치)
	  cd 설치되어 있는 vcpkg-root
	  vcpkg remove fmt:x64-windows-static
	  vcpkg install fmt:x64-windows-static
    ```
  - 2. 업데이트 후보 확인후 업그레이드 하기
  ```powershell
    [string]$Triplet = "x64-windows-static"
	# 설치중 일부 실패해도 가능한 포트는 계속 업그레이드 진행
	[switch]$KeepGoing = $false # (--keep-going 적용)
	[string]$OverlayPorts = ".\overlays\ports"
	[string]$OverlayTriplets = ".\overlays/triplets"
	[switch]$WhatIf
  
	Write-Host "==> vcpkg update (업데이트 후보 확인) ..." -ForegroundColor Cyan
	Set-Location "E:\Library\vcpkg-root"
	$updatedOutput = "vcpkg update --overlay-ports=$OverlayPorts --overlay-ports=$OverlayTripletss 2>&1"

	# 후보 유무 판별(여러 출력 포맷 고려: 'is outdated', '→', 'updates are available', 'No packages need updating' 등)
	$hasUpdates = ( $updateOutput -match 'outdated' ) -or
				  ( $updateOutput -match 'updates? are available' ) -or
				  ( $updateOutput -match '->' ) -or
				  ( -not ($updateOutput -match 'No packages need updating') )
	if (-not $hasUpdates) {
		Write-Host "==> 업그레이드할 패키지가 없습니다." -ForegroundColor Green
		return
	}
	
	$upgradeArgs = @("upgrade", "--no-dry-run")
	if ($Triplet)   { $upgradeArgs += @("--triplet", $Triplet) }
	if ($KeepGoing) { $upgradeArgs += "--keep-going" }
	if ($OverlayPorts)    { $upgradeArgs += "--overlay-ports=$OverlayPorts" }
	if ($OverlayTriplets) { $upgradeArgs += "--overlay-triplets=$OverlayTriplets" }	
  
	& vcpkg @($upgradeArgs)
	if ($LASTEXITCODE -eq 0) {
		Write-Host "==> 업그레이드 완료." -ForegroundColor Green
	} else {
		Write-Host "==> 업그레이드 중 오류가 발생했습니다. 코드: $LASTEXITCODE" -ForegroundColor Red
		exit $LASTEXITCODE
	}
  ```

##### Overlay Port : 특정 Port의 설치 과정을 재정의
  - 디렉토리 구성
  ```markdown
	vcpkg-root/
	├─ vcpkg.exe
	├─ vcpkg-configuration.json       	← (여기서 vcpkg CLI를 실행할 때 읽힘)
	├─ installed/<triplet>				← triplet 설정으로 설치된 패키지
	└─ overlays/
	   └─ ports/
		  └─ fmt/                     	← 오버레이 포트(스켈레톤 그대로)
			 ├─ vcpkg.json or CONTROL
			 ├─ portfile.cmake
			 ├─ patches/   (선택)
			 ├─ cmake/     (선택)
			 └─ usage      (선택)
  ```
  - vcpkg-root\vcpkg-configuration.json
  ```json
	"overlay-ports": [
		"overlays/ports"
	],
	"overlay-triplets": [
	    "overlays/triplets"
	],
	"registries": [
		{
		  "kind": "builtin",
		  "baseline": "51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf" <= Commit SHA512
		}
	]
  ```
  - vcpkg-root\overlays\ports\fmt\vcpkg.json
  ```json
	"name": "fmt",
	"version-semver": "10.1.1",
	"description": "fmt pinned by overlay (fixed upstream tag/commit)",
	"homepage": "https://github.com/fmtlib/fmt",
	"license": "MIT"
  ```
  - vcpkg-root\overlays\ports\fmt\portfile.cmake
  ```cmake
	# from GIT (선택)
	vcpkg_from_git(
		OUT_SOURCE_PATH SOURCE_PATH 	# vcpkg가 다운로드·검증·압축해제한 소스 디렉터리의 경로를 이 변수(SOURCE_PATH)에 출력
		URL https:// 					# Git 리포지토리 같은 단일 엔드포인트
		REF "${VERSION}"				# 가져올 소스의 기준점, 원하는 태그명, 커밋 SHA, 브랜치명 (예: 10.1.1)
		SHA512 0						# 다운로드한 소스 아카이브의 무결성 검증 해시
		HEAD_REF 브랜치명					# 참조할 브랜치
	)
	# -------------------------------------------------------------------------	
	
	# from GitHub (선택)
	vcpkg_from_github(
		OUT_SOURCE_PATH SOURCE_PATH
		REPO xxx/xxx
		REF x.x.x
		SHA512 0
	)
	# -------------------------------------------------------------------------
	
	# from Archive URL (선택)
	vcpkg_download_distfile(
		OUT_PATH ARCHIVE				# 내려받은 로컬 파일 경로를 ARCHIVE 변수에 출력
		URLS https://					# 다운로드 소스 URL 목록(1개 이상). 여러 개를 주면 순서대로 시도하여 첫 성공을 사용
		SHA512 0
	)
	vcpkg_extract_source_archive(
		OUT_SOURCE_PATH SOURCE_PATH
		ARCHIVE ${ARCHIVE}				# vcpkg_download_distfile가 내려준 아카이브 파일 경로
	)
	# -------------------------------------------------------------------------

	vcpkg_cmake_configure(
		SOURCE_PATH "${SOURCE_PATH}"
		OPTIONS
			-DFMT_CMAKE_DIR=share/fmt
			-DFMT_TEST=OFF
			-DFMT_DOC=OFF
	)

	vcpkg_cmake_install()
	vcpkg_cmake_config_fixup()
	vcpkg_fixup_pkgconfig()
	vcpkg_copy_pdbs()

	file(REMOVE_RECURSE
		"${CURRENT_PACKAGES_DIR}/debug/include"
		"${CURRENT_PACKAGES_DIR}/debug/share"
	)

	file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
	vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
  ```
  - 포트 변경 적용
  ```powershell
  cd 설치되어 있는 vcpkg-root
  vcpkg install fmt:x64-windows-static
  ```

##### Overlay Port & Triplet : 특정 Port & Triplet 설치 과정을 재정의
  - 특정 Port의 설치 과정을 재정의 (위의 내용 참조)
  - 설치 과정을 재정의한 Port를 별도로 설치되도록 Triplet을 재정의
  - 주요 설치 경로
  ```markdown
	vcpkg-root/
	├─ ...
	└─ overlays/
	   └─ triplets/
		  └─ x64-windows-static-custom-app.cmake
  ```
  - vcpkg-root/overlays/triplets/x64-windows-static-custom-app.cmake
  ```cmake
	# vcpkg-root/overlays/triplets/x64-windows-static-mt.cmake

	set(VCPKG_TARGET_ARCHITECTURE x64)
	set(VCPKG_CMAKE_SYSTEM_NAME Windows)
	set(VCPKG_CRT_LINKAGE static)   # /MT
	set(VCPKG_LIBRARY_LINKAGE static)
  ``` 
  - 포트 변경 적용
  ```powershell
  cd 설치되어 있는 vcpkg-root
  vcpkg install x64-windows-static-mt
  ``` 

#### Manifest 모드
  - Before 정보
  - my-proejct/vcpkg.json
  ```json
	"name": "my-project",
	"version": "0.0.1",
	"builtin-baseline": "Old SHA512",
	"dependencies": [
		// 1) 정확히 특정 버전 고정(“version-string”/“version-semver”/“version-date” 중 하나)
		{ "name": "fmt", "version-semver": "10.2.1" },
		
		// 2) 최소 버전 이상 허용 (업그레이드 여지)
		{ "name": "openssl", "version>=": "3.2.0" }
	],
	// 3) 상위 제약을 덮어씌우는 강제 고정이 필요할 때(특정 포트만 핀)
	"overrides": [
		{ "name": "cpprestsdk", "version-semver": "2.10.18" }
	]
  ```
  - After 정보
  - my-proejct/vcpkg.json ​
  ```json
	# 수정되는 항목만 작성, 기타는 생략
  	"builtin-baseline": "New SHA512",  ← (필요한 경우는 수정 !!!)
	...
	"dependencies": [
		...
		{ "name": "fmt", "version-semver": "11.0.0" }
		...
	]
  ``` 
  - 포트 변경 적용 : 전체 설치
  ```powershell
	cd 설치되어 있는 my-project
	vcpkg install --x-manifest-root="C:\src\my-project" --x-install-root="C:\src\my-project\vcpkg_installed" ^
	              x64-windows-static
  ```
  - 포트 변경 적용 : 해당 포트 삭제후 설치
  ```powershell
	cd 설치되어 있는 my-project
	vcpkg remove --recurse fmt:x64-windows-static
	vcpkg install --x-manifest-root="C:\src\my-project" --x-install-root="C:\src\my-project\vcpkg_installed" ^
	              fmt:x64-windows-static
  ```  

### 패키지 제거 (Package Remove)

#### Classic 모드에서 삭제
  - 특정 패키지: 트리플릿 삭제
    - vcpkg remove <포트명:트리플릿명>
    ```
    vcpkg remove zlib:x64-windows
    ```
  - 복수개의 패키지:트리플릿 및 의존적인 패키지들을 함께 삭제(권장)
    - vcpkg remove --recurse <포트명:트리플릿명> ...
    ```
    vcpkg remove --recurse openssl:x64-windows zlib:x64-windows-static zlib:arm64-windows
    ```

  - 실제로 지우기 전 계획만 확인
    - vcpkg remove --recurse --dry-run <포트명:트리플릿명> ...
    ```
    vcpkg remove --recurse --dry-run openssl:x64-windows zlib:x64-windows-static
    ```
#### Manifest 모드에서 삭제
  - Manifest 모드에선 명령어로 삭제할 수 없다.
  - vcpkg.json 수정 => vcpkg install 실행, 재설치 과정을 통해 삭제되게 한다 !!!

##### Port 삭제
  - vcpkg.json 수정전
  ```
  "dependencies": ["zlib", "openssl"],
  ```
  - vcpkg.json 수정후
  ```
  "dependencies": ["openssl"],
  ```
  - vcpkg 패키지 재설치
  ```
  vcpkg install --triplet x64-windows
  ```
##### feature 삭제
  - vcpkg.json 수정전
  ```
  { "name": "openssl", "features": ["tools"] }
  ```
  - vcpkg.json 수정후
  ```
  { "name": "openssl", "default-features": false }   // or features 제거
  ```
  - vcpkg 패키지 재설치
  ```
  vcpkg install --triplet x64-windows
  ```
##### 패키지 전체 삭제
  - vcpkg_installed/ ← 폴더 통째로 삭제(프로젝트 루트)


---


## CMake 빌드 시스템 생성
  - CMake : 빌드 시스템 생성기, 선택한 Generator에 따라 내부적으로 MSBuild(Visual Studio), Ninja, NMake 등을 호출
  - Generator 명령어
    - cmake -S <소스> -B <빌드> [-G <Generator>] [옵션...]

### Generator 종류

#### Visual Studio (MSBuild, Windows / Multi-Config)
	​```
	cmake -S . -B build\vs2022 ^
	  -G "Visual Studio 17 2022" -A x64 ^
	  -DCMAKE_TOOLCHAIN_FILE=C:\vcpkg\scripts\buildsystems\vcpkg.cmake ^
	  -DVCPKG_TARGET_TRIPLET=x64-windows
	
	cmake --build build\vs2022 --config Release -- /m
	ctest --test-dir build\vs2022 -C Release
	​```

#### Ninja + MSVC (Windows / Single-Config)
	​```
	cmake -S . -B build\ninja ^
	  -G "Ninja" -DCMAKE_BUILD_TYPE=Release ^
	  -DCMAKE_TOOLCHAIN_FILE=C:\vcpkg\scripts\buildsystems\vcpkg.cmake ^
	  -DVCPKG_TARGET_TRIPLET=x64-windows
	
	cmake --build build\ninja -j 8
	​```

#### Ninja Multi-Config (Windows·Linux·macOS / Multi-Config)
	​```
	cmake -S . -B build/ninja-multi -G "Ninja Multi-Config" \
	  -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake \
	  -DVCPKG_TARGET_TRIPLET=x64-windows
	
	cmake --build build/ninja-multi --config RelWithDebInfo
	​```

#### Unix Makefiles (Linux/macOS / Single-Config)
	​```
	CC=gcc CXX=g++ cmake -S . -B build/make -G "Unix Makefiles" \
	  -DCMAKE_BUILD_TYPE=Release \
	  -DCMAKE_TOOLCHAIN_FILE=/opt/vcpkg/scripts/buildsystems/vcpkg.cmake \
	  -DVCPKG_TARGET_TRIPLET=x64-linux
	
	cmake --build build/make -j$(nproc)
	​```

#### Ninja (Linux/macOS / Single-Config, Clang 예)
	​```
	CC=clang CXX=clang++ cmake -S . -B build/ninja -G Ninja \
	  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
	  -DCMAKE_TOOLCHAIN_FILE=/opt/vcpkg/scripts/buildsystems/vcpkg.cmake \
	  -DVCPKG_TARGET_TRIPLET=x64-linux
	
	cmake --build build/ninja -j$(nproc)
	​```

#### Xcode (macOS / Multi-Config)
	​```
	cmake -S . -B build/xcode -G Xcode \
	  -DCMAKE_TOOLCHAIN_FILE=/opt/vcpkg/scripts/buildsystems/vcpkg.cmake \
	  -DVCPKG_TARGET_TRIPLET=arm64-osx
	
	cmake --build build/xcode --config Release
	​```

#### NMake Makefiles (Windows / Single-Config, 간단 참고)
	​```
	cmake -S . -B build\nmake -G "NMake Makefiles" ^
	  -DCMAKE_BUILD_TYPE=Release ^
	  -DCMAKE_TOOLCHAIN_FILE=C:\vcpkg\scripts\buildsystems\vcpkg.cmake ^
	  -DVCPKG_TARGET_TRIPLET=x64-windows
	
	cmake --build build\nmake
	​```
	
	---


## 8. 클래식(Classic) & 매니페스트(Manifest) 정리

| 항목       | Classic                       | Manifest                    |
| -------- | ----------------------------- | --------------------------- |
| 의존성 선언   | CLI에서 수동 설치 (`vcpkg install`) | `vcpkg.json` 작성             |
| 버전 재현성   | 약함                            | **baseline + 버전조건**으로 강함    |
| 적용 범위    | 전역(공유 `installed/`)           | 프로젝트/빌드 폴더에 **격리**          |
| 통합 난이도   | 매우 쉬움                         | 초기 설정 필요(toolchain/presets) |
| CI/CD 적합 | 보통                            | **매우 높음**                   |

  - **클래식**: `vcpkg integrate install`로 VS 전역 통합 → 빠른 실험/샘플
  - **매니페스트**: 프로젝트 루트 `vcpkg.json`(+ `vcpkg-configuration.json`) → 팀/프로덕션 권장


---


## 9. 설치 트리(설치 위치)와 확인 방법
  - **매니페스트 + CMake 기본값**  
      `./build(또는 지정 경로)/vcpkg_installed/<triplet>/{include,lib,debug,share,tools,...}`
  - **클래식(전역) 기본값**  
      `<vcpkg_root>/installed/<triplet>/{include,lib,debug,share,tools,...}`

  **CMake에서 확인**
	​```cmake
	message(STATUS "VCPKG_INSTALLED_DIR = ${VCPKG_INSTALLED_DIR}")
	message(STATUS "VCPKG_TARGET_TRIPLET = ${VCPKG_TARGET_TRIPLET}")
	​```

---


## 10. 빠른 시작(Quick Start)

### Classic 설치
	​```
	vcpkg install zlib:x64-windows openssl:x64-windows
	vcpkg integrate install
	# VS에서 자동 include/link
	​```

### Manifest 설치
  - 프로젝트 루트에 `vcpkg.json` 작성
  - CMake Toolchain 지정 후 빌드:
  ```
  cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=C:/Tools/vcpkg/scripts/buildsystems/vcpkg.cmake -DVCPKG_FEATURE_FLAGS=manifests
  cmake --build build --config Release
  ```

---

## 11. CMake & Visual Studio 통합

### CMakePresets.json (권장)
	​```json
	{
	  "version": 6,
	  "configurePresets": [
		{
		  "name": "x64-windows",
		  "generator": "Ninja",
		  "binaryDir": "build/x64-windows",
		  "cacheVariables": {
			"CMAKE_TOOLCHAIN_FILE": "C:/Tools/vcpkg/scripts/buildsystems/vcpkg.cmake",
			"VCPKG_TARGET_TRIPLET": "x64-windows",
			"VCPKG_FEATURE_FLAGS": "manifests"
		  }
		}
	  ]
	}
	​```

### MSBuild(선택) — Directory.Build.props/targets (전역 통합 대안)
	​```xml
	<!-- Directory.Build.props -->
	<Project>
	  <Import Project="$(MSBuildThisFileDirectory)vcpkg\scripts\buildsystems\msbuild\vcpkg.props" />
	</Project>
	​```
	​```xml
	<!-- Directory.Build.targets -->
	<Project>
	  <Import Project="$(MSBuildThisFileDirectory)vcpkg\scripts\buildsystems\msbuild\vcpkg.targets" />
	</Project>
	​```
	
	> 또는 전역으로 `vcpkg integrate install` 실행.

---


## 12. Overlay Ports
  - 목적: **내 포트 레시피**를 공식보다 **우선 적용**(Custom/Patch/사내용)
  - 선언 위치: REPO 루트 또는 프로젝트 루트 아래 `vcpkg-configuration.json`
  ```json
  {
    "default-registry": { "kind": "builtin", "baseline": "<PINNED_SHA>" },
    "overlay-ports": ["./overlays/ports"]
  }
  ```
  - Overlay Ports 경로내에 해당 포트의 포트 폴더 스켈레톤(Port Folder Skeleton) 작성
     ```
     /overlays/ports/<port-name>/
     				 ├─ vcpkg.json            		# 포트 메타데이터(버전/의존성/피처/라이선스 등)
     				 ├─ portfile.cmake        		# 실제 빌드/설치 스크립트
     				 ├─ patches/              		# (선택) 소스 패치들 *.patch
     				 ├─ cmake/                		# (선택) 보조 CMake 스크립트
     				 ├─ vcpkg-cmake-wrapper.cmake   # (선택) find_package 개선용 래퍼
     				 └─ usage                 		# (선택) 설치 후 안내 문구
     ```
  - 소스 취득 방식 3가지: **로컬 번들** / **원격 URL·Repo 핀 고정** / **레시피만 오버라이드**

---

## 13. Overlay Triplets
- 목적: **빌드 정책**(정적/동적/CRT/툴체인/크로스)을 내 레포 기준으로 **강제**
- 선언 위치: REPO 루트 또는 프로젝트 루트 아래 `vcpkg-configuration.json`
```json
{
	"default-registry": { "kind": "builtin", "baseline": "<PINNED_SHA>" },
	"overlay-triplets": ["./overlays/triplets"]
}
```

### 정적 라이브러리 + 동적 CRT(/MD)
```
overlays/triplets/x64-windows-static-md.cmake
```
```cmake
set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CMAKE_SYSTEM_NAME Windows)
set(VCPKG_LIBRARY_LINKAGE static)  # .lib
set(VCPKG_CRT_LINKAGE dynamic)     # /MD
# set(VCPKG_PLATFORM_TOOLSET v143)  # 선택
```

---


## 14. Binary Cache
  - 환경 변수 지정:
    - Windows : PowerShell
    ```powershell
    $env:VCPKG_DEFAULT_BINARY_CACHE="C:\vcpkg_cache"
    ```
    - Linux/macOS : bash
    ```bash
    export VCPKG_DEFAULT_BINARY_CACHE="$HOME/.cache/vcpkg"
    ```

- CI 에서는 캐시 폴더 **복원/보관**으로 빌드 시간 절감


---


## 15. Visual Studio Vcpkg 속성 페이지 : 항목별 가이드

> Tip: `vcpkg integrate install` 또는 `Directory.Build.props & targets` 통합이 선행되어야 탭이 보입니다.

| UI 항목                                 | MSBuild 속성                     | 의미 / 언제 켤까                         | 권장값                                      |
| ------------------------------------- | ------------------------------ | ---------------------------------- | ---------------------------------------- |
| **Use Vcpkg**                         | `VcpkgEnabled`                 | 프로젝트에서 vcpkg 통합 사용 여부              | **Yes**                                  |
| **Use Vcpkg Manifest**                | `VcpkgEnableManifest`          | `vcpkg.json` 기반 **자동 복원** 사용       | 매니페스트 쓸 땐 **Yes**                        |
| **Install Vcpkg Dependencies**        | `VcpkgManifestInstall`         | 빌드시 의존성 **자동 설치/복원**               | 보통 **Yes**. CI에서 별도 복원 시 **No**          |
| **Use AutoLink**                      | `VcpkgAutoLink`                | vcpkg가 **Include/Lib/Link**를 자동 주입 | **Yes** (단, clang-cl + lld-link 환경은 **No** 후 수동 링크) |
| **App-locally deploy DLLs**           | `VcpkgApplocalDeps`            | 런타임 DLL을 출력 폴더로 **자동 복사**          | 개발·디버깅 **Yes**, 배포 전략 따라 **선택**          |
| **Use built-in app-local deployment** | `VcpkgXUseBuiltInApplocalDeps` | vcpkg의 실험적 DLL 복사 로직 사용            | 기본 **No**                                |
| **Installed Directory**               | `VcpkgInstalledDir`            | 설치 트리 위치 지정                        | 기본 유지(매니페스트: `$(VcpkgManifestRoot)\vcpkg_installed\$(VcpkgTriplet)\`) |
| **Host Triplet**                      | `VcpkgHostTriplet`             | 호스트 도구 빌드용 트리플릿                    | 기본(대개 `x64-windows`)                     |
| **Triplet**                           | `VcpkgTriplet`                 | 타깃 플랫폼/정책 조합                       | **가장 중요**. `x64-windows`/`x64-windows-static`/`x64-windows-static-md` 등 |
| **Use Static Libraries**              | -                              | 정적 라이브러리 의도 토글(편의)                 | **Triplet으로 직접 통제** 권장                   |
| **Use Dynamic CRT**                   | -                              | `/MD` 의도 토글(편의)                    | **Triplet으로 직접 통제** 권장                   |

> **주의**: 자동 추론은 “**동적 라이브러리 + /MD**”만 완전 커버합니다. 정적 계열(/MT)이나 혼합 정책은 **Triplet에 명시**해야 합니다.

---


## 16. Header include & Library Link 자동 설정

### 통합

- 전역: `vcpkg integrate install` **한 번** 실행 **또는**
- 프로젝트: `Directory.Build.props/targets`로 vcpkg MSBuild 가져오기

### 프로젝트 속성 : Vcpkg 속성 페이지

- **Use Vcpkg = Yes**
- **Use AutoLink = Yes**  ← include & Link 자동 설정
- **Triplet = 원하는 정책**  
  - 기본(DLL, /MD): `x64-windows`  
  - 완전 정적(/MT): `x64-windows-static`  
  - 정적 + 동적 CRT(/MD): `x64-windows-static-md`
- (매니페스트 시) **Use Vcpkg Manifest = Yes**, **Install Vcpkg Dependencies = Yes**
- (편의) **App-locally deploy DLLs = Yes**

### 의존성 설치

- Manifest : 빌드시 자동 복원
- Classic : `vcpkg install fmt:x64-windows zlib:x64-windows` 등 수동 설치

---


## 17. 테스트 예제 모음
  - VCPkgTest 솔루션 주요 코드 참조
