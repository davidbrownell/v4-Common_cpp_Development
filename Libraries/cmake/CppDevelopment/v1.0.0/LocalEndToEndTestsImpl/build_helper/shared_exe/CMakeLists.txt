cmake_minimum_required(VERSION 3.5.0)

set(CMAKE_MODULE_PATH "$ENV{DEVELOPMENT_ENVIRONMENT_CMAKE_MODULE_PATH}")

if(NOT WIN32)
    string(REPLACE ":" ";" CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}")
endif()

include(BuildHelpers)

function(Impl)
    get_filename_component(_this_path ${CMAKE_CURRENT_LIST_FILE} DIRECTORY)

    include(${_this_path}/../shared/shared.cmake)

    build_binary(
        NAME
            SharedExe

        FILES
            ${_this_path}/../../shared_exe.cpp

        LINK_LIBRARIES
            Shared

        COMPANY_NAME MyCompany
        VERSION_MAJOR 7
        VERSION_MINOR 8
        VERSION_PATCH 9
    )
endfunction()

Impl()
