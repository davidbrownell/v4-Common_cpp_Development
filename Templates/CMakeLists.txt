cmake_minimum_required(VERSION 3.5.0)

MESSAGE(FATAL_ERROR "TODO: Replace '<project_name>' on the next line")
project(<project_name> LANGUAGES CXX)

set(CMAKE_MODULE_PATH "$ENV{DEVELOPMENT_ENVIRONMENT_CMAKE_MODULE_PATH}")

if(NOT WIN32)
    string(REPLACE ":" ";" CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}")
endif()

# Set compiler options here
#
# set(CppDevelopment_STATIC_CRT ON CACHE BOOL "" FORCE)
# set(CppDevelopment_NO_ADDRESS_SPACE_LAYOUT_RANDOMIZATION ON CACHE BOOL "" FORCE)

include(BuildHelpers)

function(Impl)
    # Include cmake modules here
    #
    # include(FooModule)

    get_filename_component(_this_path ${CMAKE_CURRENT_LIST_FILE} DIRECTORY)

    MESSAGE(FATAL_ERROR "Call 'build_binary()', 'build_library()', or 'build_tests()' on the next line")
    # Add call here
endfunction()

Impl()
