cmake_minimum_required(VERSION 3.22)
project(foodsticker)

# ncnn 预编译包（Vulkan开启版）: https://github.com/Tencent/ncnn/releases
# 解压到 app/src/main/cpp/ncnn-android-vulkan/
set(ncnn_DIR ${CMAKE_SOURCE_DIR}/ncnn-android-vulkan/${ANDROID_ABI}/lib/cmake/ncnn)
find_package(ncnn REQUIRED)

add_library(native_engine SHARED native_engine.cpp)
target_link_libraries(native_engine ncnn jnigraphics android log)
