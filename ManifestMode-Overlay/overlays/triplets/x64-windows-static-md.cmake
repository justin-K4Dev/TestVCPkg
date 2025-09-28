# overlays/triplets/x64-windows-static-md.cmake

set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CMAKE_SYSTEM_NAME Windows)
set(VCPKG_CRT_LINKAGE dynamic)  # /MD
set(VCPKG_LIBRARY_LINKAGE static)


# =================================================================================================
# CMake 제너레이터/플랫폼/툴셋 설정
# =================================================================================================
# set(VCPKG_CMAKE_GENERATOR "Visual Studio 17 2022")
# set(VCPKG_CMAKE_GENERATOR_PLATFORM "x64")   # x64
# set(VCPKG_CMAKE_GENERATOR_TOOLSET "v143,version=14.44.35207")   # v143 (선택)

# =================================================================================================
# CMake CMAKE_C_COMPILER & CMAKE_CXX_COMPILER MSVC cl.exe 설정
# =================================================================================================
# set(CMAKE_C_COMPILER cl CACHE FILEPATH "" FORCE)
# set(CMAKE_CXX_COMPILER cl CACHE FILEPATH "" FORCE)