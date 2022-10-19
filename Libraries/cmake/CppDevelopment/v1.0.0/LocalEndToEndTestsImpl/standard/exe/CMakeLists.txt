cmake_minimum_required(VERSION 3.5.0)

macro(Impl)
    set(_project_name Exe)
    set(_version_major 1)
    set(_version_minor 2)
    set(_version_patch 3)
    set(_version_prerelease_info "")
    set(_version_build_info "")

    set(_version ${_version_major}.${_version_minor}.${_version_patch})

    # Alpha version components (which are supported in SemVer) present problems
    # for cmake when the version is provided inline. However, things work as expected
    # when setting the version as a property.
    project(${_project_name} LANGUAGES CXX)
    set(PROJECT_VERSION ${_version})

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
    include(GenerateFileAttributes)

    generate_file_attributes(
        _exe_file_attribute_sources
        NAME ${_project_name}
        COMPANY_NAME MyCompany
        VERSION_MAJOR ${_version_major}
        VERSION_MINOR ${_version_minor}
        VERSION_PATCH ${_version_patch}
        VERSION_PRERELEASE_INFO ${_version_prerelease_info}
        VERSION_BUILD_INFO ${_version_build_info}
    )

    # All paths should be relative to `${_this_path}`.
    get_filename_component(_this_path ${CMAKE_CURRENT_LIST_FILE} DIRECTORY)

    include(${_this_path}/../lib/lib.cmake)

    add_executable(
        ${_project_name}
        ../../exe.cpp
        ${_exe_file_attribute_sources}
    )

    set_target_properties(
        ${_project_name} PROPERTIES
        VERSION ${_version}
        SOVERSION ${_version_major}
    )

    target_link_libraries(
        ${_project_name}
        Lib
    )

    target_include_directories(
        ${_project_name} PRIVATE
        ${_includes}
    )

    target_link_directories(
        ${_project_name} PRIVATE
        ${_libs}
    )
endmacro()

Impl()
