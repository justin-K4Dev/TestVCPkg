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