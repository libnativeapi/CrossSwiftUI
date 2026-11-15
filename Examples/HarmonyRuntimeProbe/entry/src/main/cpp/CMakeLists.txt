cmake_minimum_required(VERSION 3.16)
project(SwiftRuntimeProbe LANGUAGES CXX)

set(SWIFT_INPUTS "${CMAKE_CURRENT_SOURCE_DIR}/../../../../.build/runtime")
set(NATIVEAPI_SWIFT_PATH "$ENV{NATIVEAPI_SWIFT_PATH}")
if(NOT NATIVEAPI_SWIFT_PATH)
  get_filename_component(NATIVEAPI_SWIFT_PATH
    "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../../../nativeapi/bindings/swift" ABSOLUTE)
endif()
add_subdirectory("${NATIVEAPI_SWIFT_PATH}/ohos" nativeapi-swift-ohos)

add_library(swiftprobe SHARED probe.cpp arkui_probe.cpp gallery_host.cpp "${SWIFT_INPUTS}/Probe.o"
  "${SWIFT_INPUTS}/SwiftUIRuntime.o" "${SWIFT_INPUTS}/SwiftUI.o" "${SWIFT_INPUTS}/FluentIcons.o"
  "${SWIFT_INPUTS}/DazzUI.o")
target_compile_features(swiftprobe PRIVATE cxx_std_17)
target_link_options(swiftprobe PRIVATE -Wl,--no-undefined -Wl,--exclude-libs,ALL)
nativeapi_target_link_swift_ohos(swiftprobe "${SWIFT_INPUTS}")
target_link_libraries(swiftprobe PRIVATE
  libace_napi.z.so
  ace_ndk.z
  native_drawing
  c++_shared
  uv
  dl
  m
)
