cmake_minimum_required(VERSION 3.5.0)

set(_includes "$ENV{INCLUDE}")
set(_libs "$ENV{LIB}")
set(CMAKE_MODULE_PATH "$ENV{DEVELOPMENT_ENVIRONMENT_CMAKE_MODULE_PATH}")

if(NOT WIN32)
    string(REPLACE ":" ";" CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}")
    string(REPLACE ":" ";" _includes "${_includes}")
    string(REPLACE ":" ";" _libs "${_libs}")
endif()

include(CppDevelopment)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# All paths should be relative to `${_this_path}`.
get_filename_component(_this_path ${CMAKE_CURRENT_LIST_FILE} DIRECTORY)

include(${_this_path}/shared.cmake)
