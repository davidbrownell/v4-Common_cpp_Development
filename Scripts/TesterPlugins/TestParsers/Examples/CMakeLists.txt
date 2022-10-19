cmake_minimum_required(VERSION 3.5.0)

project(CMakeExample LANGUAGES CXX)

set(CMAKE_MODULE_PATH "$ENV{DEVELOPMENT_ENVIRONMENT_CMAKE_MODULE_PATH}")

if(NOT WIN32)
    string(REPLACE ":" ";" CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}")
endif()

include(cmake/CMakeExample.cmake)
