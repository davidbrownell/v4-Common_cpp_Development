cmake_minimum_required(VERSION 3.5.0)

function(Impl)
    # Introducing a new scope to set local variables
    set(_project_name Lib)
    set(_${_project_name}_version_major 2)
    set(_${_project_name}_version_minor 0)
    set(_${_project_name}_version_patch a1)
    set(_${_project_name}_version ${_${_project_name}_version_major}.${_${_project_name}_version_minor}.${_${_project_name}_version_patch})

    set(CMAKE_CXX_STANDARD 17)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    set(CMAKE_CXX_EXTENSIONS OFF)

    set(_includes "$ENV{INCLUDE}")
    set(_libs "$ENV{LIB}")
    set(CMAKE_MODULE_PATH "$ENV{DEVELOPMENT_ENVIRONMENT_CMAKE_MODULE_PATH}")

    if(NOT WIN32)
        string(REPLACE ":" ";" CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}")
        string(REPLACE ":" ";" _includes "${_includes}")
        string(REPLACE ":" ";" _libs "${_libs}")
    endif()

    include(CppDevelopment)

    # All paths should be relative to `${_this_path}`.
    get_filename_component(_this_path ${CMAKE_CURRENT_LIST_FILE} DIRECTORY)

    add_library(
        ${_project_name}
        STATIC
        ${_this_path}/../../lib.cpp
    )

    set_target_properties(
        ${_project_name} PROPERTIES
        VERSION ${_${_project_name}_version}
        SOVERSION ${_${_project_name}_version_major}
    )

    target_include_directories(
        ${_project_name}
        INTERFACE
        ${_this_path}
    )
endfunction()

Impl()
