cmake_minimum_required(VERSION 3.10)
project(MyApp)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

# ==============================================
# 程序在 bin 目录，库在同级 lib 目录，自动查找
# ==============================================

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# 仅加载动态库
set(CMAKE_FIND_LIBRARY_SUFFIXES .so)

# 依赖
find_package(Qt5 REQUIRED COMPONENTS Core Widgets)
find_package(CURL REQUIRED)

# 安装目录：cmake --install 会自动生成 bin/lib 结构
set(CMAKE_INSTALL_PREFIX ${CMAKE_SOURCE_DIR}/deploy)

# ======================
# 1. CLI 工具1
# ======================
add_executable(cli_tool1 src/cli1/main.cpp)
target_link_libraries(cli_tool1 Qt5::Core ${CURL_LIBRARIES})
target_include_directories(cli_tool1 PRIVATE ${CURL_INCLUDE_DIRS})
install(TARGETS cli_tool1 RUNTIME DESTINATION bin)

# ======================
# 2. CLI 工具2
# ======================
add_executable(cli_tool2 src/cli2/main.cpp)
target_link_libraries(cli_tool2 Qt5::Core ${CURL_LIBRARIES})
target_include_directories(cli_tool2 PRIVATE ${CURL_INCLUDE_DIRS})
install(TARGETS cli_tool2 RUNTIME DESTINATION bin)

# ======================
# 3. GUI 程序
# ======================
add_executable(gui_app src/gui/main.cpp)
target_link_libraries(gui_app Qt5::Core Qt5::Widgets)
install(TARGETS gui_app RUNTIME DESTINATION bin)