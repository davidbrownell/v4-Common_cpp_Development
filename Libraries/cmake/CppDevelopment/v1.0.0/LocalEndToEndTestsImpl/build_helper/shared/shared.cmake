cmake_minimum_required(VERSION 3.5.0)

set(CMAKE_MODULE_PATH "$ENV{DEVELOPMENT_ENVIRONMENT_CMAKE_MODULE_PATH}")

if(NOT WIN32)
    string(REPLACE ":" ";" CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}")
endif()

include(BuildHelpers)

function(Impl)
    get_filename_component(_this_path ${CMAKE_CURRENT_LIST_FILE} DIRECTORY)

    include(${_this_path}/../lib/lib.cmake)

    build_binary(
        NAME
            Shared

        IS_SHARED
            True

        FILES
            ${_this_path}/../../shared.cpp
            ${_this_path}/../../shared.h

        VERSION_MAJOR 4
        VERSION_MINOR 5
        VERSION_PATCH 6
        COMPANY_NAME MyCompany

        LINK_LIBRARIES
            Lib
    )
endfunction()

Impl()
