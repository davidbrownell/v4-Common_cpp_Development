# ----------------------------------------------------------------------
# |
# |  CMakeLists.txt
# |
# |  David Brownell <db@DavidBrownell.com>
# |      2022-09-26 11:38:02
# |
# ----------------------------------------------------------------------
# |
# |  Copyright David Brownell 2022
# |  Distributed under the Boost Software License, Version 1.0. See
# |  accompanying file LICENSE_1_0.txt or copy at
# |  http://www.boost.org/LICENSE_1_0.txt.
# |
# ----------------------------------------------------------------------
cmake_minimum_required(VERSION 3.5.0)

project(CMake_UnitTests LANGUAGES CXX)

set(CMAKE_MODULE_PATH "$ENV{DEVELOPMENT_ENVIRONMENT_CMAKE_MODULE_PATH}")

if(NOT WIN32)
    string(REPLACE ":" ";" CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}")
endif()

enable_testing()

include(BuildHelpers)
include(Catch2)

function(Impl)
    get_filename_component(_this_path ${CMAKE_CURRENT_LIST_FILE} DIRECTORY)

    include(${_this_path}/../CMake/CMakeExample.cmake)

    build_tests(
        FILES
            ${_this_path}/Add_UnitTest.cpp
            ${_this_path}/Subtract_UnitTest.cpp

        LINK_LIBRARIES
            CMakeExample
            Catch2::Catch2WithMain
    )
endfunction()

Impl()
