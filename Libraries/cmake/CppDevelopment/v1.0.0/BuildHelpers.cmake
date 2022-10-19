# ----------------------------------------------------------------------
# |
# |  BuildHelpers.cmake
# |
# |  David Brownell <db@DavidBrownell.com>
# |      2020-05-09 14:59:15
# |
# ----------------------------------------------------------------------
# |
# |  Copyright David Brownell 2020-22
# |  Distributed under the Boost Software License, Version 1.0. See
# |  accompanying file LICENSE_1_0.txt or copy at
# |  http://www.boost.org/LICENSE_1_0.txt.
# |
# ----------------------------------------------------------------------
cmake_minimum_required(VERSION 3.5)

include(CppDevelopment)
include(GenerateFileAttributes)

include(CMakeParseArguments)

set(_BuildHelpers_CXX_STANDARD_DefaultValue 17)
set(_BuildHelpers_CXX_STANDARD_REQUIRED_DefaultValue ON)
set(_BuildHelpers_CXX_EXTENSIONS_DefaultValue OFF)

# ----------------------------------------------------------------------
function(build_binary)
    # Parse the arguments
    set(options)
                                    # Required or Default Value     Desc
                                    # -------------------------     --------------------------------
    set(single_value_args
        NAME                        # <Required>                    Name of binary
        IS_SHARED                   # OFF                           ON if building a shared object/dll, OFF is building an executable

        CXX_STANDARD                # ${_BuildHelpers_CXX_STANDARD_DefaultValue}
        CXX_STANDARD_REQUIRED       # ${_BuildHelpers_CXX_STANDARD_REQUIRED_DefaultValue}
        CXX_EXTENSIONS              # ${_BuildHelpers_CXX_EXTENSIONS_DefaultValue}

        VERSION_MAJOR               # 0                             A in the version A.B.C-foo+bar
        VERSION_MINOR               # 1                             B in the version A.B.C-foo+bar
        VERSION_PATCH               # 0                             C in the version A.B.C-foo+bar
        VERSION_PRERELEASE_INFO     # None                          foo in the version A.B.C-foo+bar
        VERSION_BUILD_INFO          # None                          bar in the version A.B.C-foo+bar

        COMPANY_NAME                # None                          See 'GenerateFileAttributes.cmake::generate_file_attributes` for default value
        FILE_DESCRIPTION            # None                          See 'GenerateFileAttributes.cmake::generate_file_attributes` for default value
        BUNDLE                      # None                          See 'GenerateFileAttributes.cmake::generate_file_attributes` for default value
        ICON                        # None                          See 'GenerateFileAttributes.cmake::generate_file_attributes` for default value
        COPYRIGHT                   # None                          See 'GenerateFileAttributes.cmake::generate_file_attributes` for default value
        COMMENTS                    # None                          See 'GenerateFileAttributes.cmake::generate_file_attributes` for default value
        ORIGINAL_FILENAME           # None                          See 'GenerateFileAttributes.cmake::generate_file_attributes` for default value
        INTERNAL_NAME               # None                          See 'GenerateFileAttributes.cmake::generate_file_attributes` for default value
    )
    set(multi_value_args
        FILES                       # <Required>                    Files to build
        INCLUDE_DIRECTORIES         # None                          Include directories
        LINK_LIBRARIES              # None                          Libraries to link
        LINK_DIRECTORIES            # None                          Link include directories
        PRECOMPILED_HEADERS         # None                          Precompiled header names
        PRECOMPILED_LIBRARY_HEADERS # None                          Library names that include precompiled headers
    )

    cmake_parse_arguments(
        BUILD
        "${options}"
        "${single_value_args}"
        "${multi_value_args}"
        ${ARGN}
    )

    # Validate required values
    _ValidateRequiredParams(
        BUILD_NAME
        BUILD_FILES
    )

    # Set defaults
    _SetValue(BUILD_IS_SHARED OFF)
    _SetValue(BUILD_CXX_STANDARD ${_BuildHelpers_CXX_STANDARD_DefaultValue})
    _SetValue(BUILD_CXX_STANDARD_REQUIRED ${_BuildHelpers_CXX_STANDARD_REQUIRED_DefaultValue})
    _SetValue(BUILD_CXX_EXTENSIONS ${_BuildHelpers_CXX_EXTENSIONS_DefaultValue})

    if("${BUILD_VERSION_PRERELEASE_INFO}" STREQUAL "")
        set(BUILD_VERSION_PRERELEASE_INFO "")
    else()
        set(BUILD_VERSION_PRERELEASE_INFO "-${BUILD_VERSION_PRERELEASE_INFO}")
    endif()

    if("${BUILD_VERSION_BUILD_INFO}" STREQUAL "")
        set(BUILD_VERSION_BUILD_INFO "")
    else()
        set(BUILD_VERSION_BUILD_INFO "+${BUILD_VERSION_BUILD_INFO}")
    endif()

    if(
        NOT "${BUILD_VERSION_MAJOR}" STREQUAL ""
        OR NOT "${BUILD_VERSION_MINOR}" STREQUAL ""
        OR NOT "${BUILD_VERSION_PATCH}" STREQUAL ""
    )
        _ValidateRequiredParams(
            BUILD_VERSION_MAJOR
            BUILD_VERSION_MINOR
            BUILD_VERSION_PATCH
        )

        if(NOT "${BUILD_COMPANY_NAME}" STREQUAL "")
            generate_file_attributes(
                _file_attribute_filenames
                NAME "${BUILD_NAME}"
                COMPANY_NAME "${BUILD_COMPANY_NAME}"
                VERSION_MAJOR "${BUILD_VERSION_MAJOR}"
                VERSION_MINOR "${BUILD_VERSION_MINOR}"
                VERSION_PATCH "${BUILD_VERSION_PATCH}"
                VERSION_PRERELEASE_INFO "${BUILD_VERSION_PRERELEASE_INFO}"
                VERSION_BUILD_INFO "${BUILD_VERSION_BUILD_INFO}"
                FILE_DESCRIPTION "${BUILD_FILE_DESCRIPTION}"
                BUNDLE "${BUILD_BUNDLE}"
                ICON "${BUILD_ICON}"
                COPYRIGHT "${BUILD_COPYRIGHT}"
                COMMENTS "${BUILD_COMMENTS}"
                ORIGINAL_FILENAME "${BUILD_ORIGINAL_FILENAME}"
                INTERNAL_NAME "${BUILD_INTERNAL_NAME}"
            )

            list(APPEND BUILD_FILES ${_file_attribute_filenames})
        endif()
    else()
        set(BUILD_VERSION_MAJOR 0)
        set(BUILD_VERSION_MINOR 1)
        set(BUILD_VERSION_PATCH 0)
    endif()

    # Apply the values
    set(PROJECT_VERSION ${BUILD_VERSION_MAJOR}.${BUILD_VERSION_MINOR}.${BUILD_VERSION_PATCH})

    set(CMAKE_CXX_STANDARD ${BUILD_CXX_STANDARD})
    set(CMAKE_CXX_STANDARD_REQUIRED ${BUILD_CXX_STANDARD_REQUIRED})
    set(CMAKE_CXX_EXTENSIONS ${BUILD_CXX_EXTENSIONS})

    set(_includes "$ENV{INCLUDE}")
    set(_libs "$ENV{LIB}")

    _MakeRelativePaths(BUILD_INCLUDE_DIRECTORIES)
    _MakeRelativePaths(_includes)
    _MakeRelativePaths(BUILD_LINK_DIRECTORIES)
    _MakeRelativePaths(_libs)

    if(NOT WIN32)
        string(REPLACE ":" ";" _includes "${_includes}")
        string(REPLACE ":" ";" _libs "${_libs}")
    endif()

    if(${BUILD_IS_SHARED})
        add_library(
            ${BUILD_NAME}
            SHARED
            ${BUILD_FILES}
        )
    else()
        add_executable(
            ${BUILD_NAME}
            ${BUILD_FILES}
        )
    endif()

    set_target_properties(
        ${BUILD_NAME}
        PROPERTIES
        VERSION ${BUILD_VERISON_MAJOR}.${BUILD_VERSION_MINOR}.${BUILD_VERSION_PATCH}
        SOVERSION ${BUILD_VERSION_MAJOR}
        LINKER_LANGUAGE CXX
    )

    foreach(_include_item IN ITEMS
        "_includes"
        "BUILD_INCLUDE_DIRECTORIES"
    )
        if(NOT "${${_include_item}}" STREQUAL "")
            target_include_directories(
                ${BUILD_NAME}
                PUBLIC
                ${${_include_item}}
            )
        endif()
    endforeach()

    foreach(_lib_item IN ITEMS
        "_libs"
        "BUILD_LINK_DIRECTORIES"
    )
        if(NOT "${${_lib_item}}" STREQUAL "")
            target_link_directories(
                ${BUILD_NAME}
                PUBLIC
                ${${_lib_item}}
            )
        endif()
    endforeach()

    if(NOT "${BUILD_LINK_LIBRARIES}" STREQUAL "")
        target_link_libraries(
            ${BUILD_NAME}
            PUBLIC
            ${BUILD_LINK_LIBRARIES}
        )
    endif()

    _ApplyPrecompiledHeaders(${BUILD_NAME} PUBLIC)
endfunction()

# ----------------------------------------------------------------------
function(build_library)
    # Parse the arguments
    set(options)
                                        # Required or Default Value     Desc
                                        # -------------------------     --------------------------------
    set(single_value_args
        NAME                            # <Required>                    Name of library
        IS_INTERFACE                    # OFF                           ON if building an interface-only library, OFF is building a standard library

        CXX_STANDARD                    # ${_BuildHelpers_CXX_STANDARD_DefaultValue}
        CXX_STANDARD_REQUIRED           # ${_BuildHelpers_CXX_STANDARD_REQUIRED_DefaultValue}
        CXX_EXTENSIONS                  # ${_BuildHelpers_CXX_EXTENSIONS_DefaultValue}
    )
    set(multi_value_args
        FILES                           # <Required>                    Files to build
        INCLUDE_DIRECTORIES             # None                          Private Include directories
        PUBLIC_INCLUDE_DIRECTORIES      # None                          Public Include directories
        PUBLIC_LINK_LIBRARIES           # None                          Libraries to link
        PUBLIC_LINK_DIRECTORIES         # None                          Link include directories
        PRECOMPILED_HEADERS             # None                          Precompiled header names
    )

    cmake_parse_arguments(
        BUILD
        "${options}"
        "${single_value_args}"
        "${multi_value_args}"
        ${ARGN}
    )

    # Do not attempt to build libraries more than once
    if(TARGET ${BUILD_NAME})
        return()
    endif()

    # Validate required values
    _ValidateRequiredParams(
        BUILD_NAME
        BUILD_FILES
    )

    # Set defaults
    _SetValue(BUILD_CXX_STANDARD ${_BuildHelpers_CXX_STANDARD_DefaultValue})
    _SetValue(BUILD_CXX_STANDARD_REQUIRED ${_BuildHelpers_CXX_STANDARD_REQUIRED_DefaultValue})
    _SetValue(BUILD_CXX_EXTENSIONS ${_BuildHelpers_CXX_EXTENSIONS_DefaultValue})

    # Apply the values
    set(CMAKE_CXX_STANDARD ${BUILD_CXX_STANDARD})
    set(CMAKE_CXX_STANDARD_REQUIRED ${BUILD_CXX_STANDARD_REQUIRED})
    set(CMAKE_CXX_EXTENSIONS ${BUILD_CXX_EXTENSIONS})

    set(_includes "$ENV{INCLUDE}")
    set(_libs "$ENV{LIB}")

    if(NOT WIN32)
        string(REPLACE ":" ";" _includes "${_includes}")
        string(REPLACE ":" ";" _libs "${_libs}")
    endif()

    _MakeRelativePaths(BUILD_INCLUDE_DIRECTORIES)
    _MakeRelativePaths(BUILD_PUBLIC_INCLUDE_DIRECTORIES)
    _MakeRelativePaths(_includes)
    _MakeRelativePaths(BUILD_PUBLIC_LINK_DIRECTORIES)
    _MakeRelativePaths(_libs)

    if(${BUILD_IS_INTERFACE})
        set(_visibility INTERFACE)

        add_library(
            ${BUILD_NAME}
            INTERFACE
        )

        target_sources(
            ${BUILD_NAME} INTERFACE
            ${BUILD_FILES}
        )
    else()
        set(_visibility PUBLIC)

        add_library(
            ${BUILD_NAME}
            ${BUILD_FILES}
        )

        foreach(_include_item IN ITEMS
            "_includes"
            "BUILD_INCLUDE_DIRECTORIES"
        )
            if(NOT "${${_include_item}}" STREQUAL "")
                target_include_directories(
                    ${BUILD_NAME}
                    PRIVATE
                    ${${_include_item}}
                )
            endif()
        endforeach()

        if(NOT "${_libs}" STREQUAL "")
            target_link_directories(
                ${BUILD_NAME}
                PRIVATE
                ${_libs}
            )
        endif()
    endif()

    if(NOT "${BUILD_PUBLIC_INCLUDE_DIRECTORIES}" STREQUAL "")
        target_include_directories(
            ${BUILD_NAME}
            ${_visibility}
            ${BUILD_PUBLIC_INCLUDE_DIRECTORIES}
        )
    endif()

    if(NOT "${BUILD_PUBLIC_LINK_LIBRARIES}" STREQUAL "")
        target_link_libraries(
            ${BUILD_NAME}
            ${_visibility}
            ${BUILD_PUBLIC_LINK_LIBRARIES}
        )
    endif()

    if(NOT "${BUILD_PUBLIC_LINK_DIRECTORIES}" STREQUAL "")
        target_link_directories(
            ${BUILD_NAME}
            ${_visibility}
            ${BUILD_PUBLIC_LINK_DIRECTORIES}
        )
    endif()

    _ApplyPrecompiledHeaders(${BUILD_NAME} ${_visibility})
endfunction()

# ----------------------------------------------------------------------
function(build_tests)
    #
    # Note that 'enable_testing()' must be called before invoking this function
    #

    # Parse the arguments
    set(options)
                                    # Required or Default Value     Desc
                                    # -------------------------     --------------------------------
    set(single_value_args
        CXX_STANDARD                # ${_BuildHelpers_CXX_STANDARD_DefaultValue}
        CXX_STANDARD_REQUIRED       # ${_BuildHelpers_CXX_STANDARD_REQUIRED_DefaultValue}
        CXX_EXTENSIONS              # ${_BuildHelpers_CXX_EXTENSIONS_DefaultValue}
    )
    set(multi_value_args
        FILES                       # <Required>                    Files to build
        INCLUDE_DIRECTORIES         # None                          Include directories
        LINK_LIBRARIES              # None                          Libraries to link
        LINK_DIRECTORIES            # None                          Link include directories
        PRECOMPILED_HEADERS         # None                          Precompiled header names
        PRECOMPILED_LIBRARY_HEADERS # None                          Library names that include precompiled headers
    )

    cmake_parse_arguments(
        BUILD
        "${options}"
        "${single_value_args}"
        "${multi_value_args}"
        ${ARGN}
    )

    # Validate required values
    _ValidateRequiredParams(
        BUILD_FILES
    )

    # Set defaults
    _SetValue(BUILD_CXX_STANDARD ${_BuildHelpers_CXX_STANDARD_DefaultValue})
    _SetValue(BUILD_CXX_STANDARD_REQUIRED ${_BuildHelpers_CXX_STANDARD_REQUIRED_DefaultValue})
    _SetValue(BUILD_CXX_EXTENSIONS ${_BuildHelpers_CXX_EXTENSIONS_DefaultValue})

    # Apply the values
    set(CMAKE_CXX_STANDARD ${BUILD_CXX_STANDARD})
    set(CMAKE_CXX_STANDARD_REQUIRED ${BUILD_CXX_STANDARD_REQUIRED})
    set(CMAKE_CXX_EXTENSIONS ${BUILD_CXX_EXTENSIONS})

    set(_includes "$ENV{INCLUDE}")
    set(_libs "$ENV{LIB}")

    if(NOT WIN32)
        string(REPLACE ":" ";" _includes "${_includes}")
        string(REPLACE ":" ";" _libs "${_libs}")
    endif()

    _MakeRelativePaths(BUILD_INCLUDE_DIRECTORIES)
    _MakeRelativePaths(_includes)
    _MakeRelativePaths(BUILD_LINK_DIRECTORIES)
    _MakeRelativePaths(_libs)

    foreach(_test_file IN ITEMS ${BUILD_FILES})
        get_filename_component(_test_name ${_test_file} NAME_WE)

        add_executable(${_test_name} ${_test_file})

        foreach(_include_item IN ITEMS
            "_includes"
            "BUILD_INCLUDE_DIRECTORIES"
        )
            if(NOT "${${_include_item}}" STREQUAL "")
                target_include_directories(
                    ${_test_name}
                    PRIVATE
                    ${${_include_item}}
                )
            endif()
        endforeach()

        foreach(_lib_item IN ITEMS
            "_libs"
            "BUILD_LINK_DIRECTORIES"
        )
            if(NOT "${${_lib_item}}" STREQUAL "")
                target_link_directories(
                    ${_test_name}
                    PRIVATE
                    ${${_lib_item}}
                )
            endif()
        endforeach()

        if(NOT "${BUILD_LINK_LIBRARIES}" STREQUAL "")
            target_link_libraries(
                ${_test_name}
                PRIVATE
                ${BUILD_LINK_LIBRARIES}
            )
        endif()

        _ApplyPrecompiledHeaders(${_test_name} PRIVATE)

        # Run all tests with verbose output except those tagged with "[benchmark]"
        add_test(
            NAME ${_test_name}
            COMMAND ${_test_name} ~[benchmark] --success
        )

        # If not in debug mode, run tests tagged with "[benchmark]". Note that we
        # don't want to run with verbose output in this scenario, as that output will
        # prevent accurate benchmark statistics.
        if(NOT "${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
            add_test(
                NAME ${_test_name}_benchmark
                COMMAND ${_test_name} [benchmark] --allow-running-no-tests
            )
        endif()
    endforeach()
endfunction()

# ----------------------------------------------------------------------
# ----------------------------------------------------------------------
# ----------------------------------------------------------------------
macro(_SetValue arg_name default_value)
    if("${${arg_name}}" STREQUAL "")
        set(${arg_name} ${default_value})
    endif()
endmacro()

# ----------------------------------------------------------------------
macro(_ValidateRequiredParams)
    foreach(_arg IN ITEMS ${ARGN})
        if("${${_arg}}" STREQUAL "")
            STRING(REGEX REPLACE "^BUILD_" "" _incoming_name ${_arg})
            MESSAGE(FATAL_ERROR "'${_incoming_name}' is a required argument")
        endif()
    endforeach()
endmacro()

# ----------------------------------------------------------------------
macro(_MakeRelativePaths var_name)
    if((CMAKE_CXX_COMPILER_ID MATCHES MSVC OR (CMAKE_CXX_COMPILER_ID MATCHES Clang AND _compiler_basename MATCHES "clang-cl.exe")) AND "${CMAKE_GENERATOR}" STREQUAL "Ninja")
        # When compiling with MSVC, Ninja will use the '/showIncludes' command line argument to
        # calculate header file dependencies. The dependencies produced by '/showIncludes' must
        # perfectly match the dependencies detected by include directives to be considered a
        # match. To ensure consistency, convert the include directives to relative paths so
        # that they match the relative paths in the output of '/showIncludes'.

        if(False)
            # Unfortunately, this technique often produces paths that are too long on windows,
            # resulting in Ninja errors. Through experimentation, it turns out that it is a better
            # solution to embed a manifest into the ninja executable to support long path names
            # on Windows.

            set(_new_items "")

            foreach(_item IN ITEMS ${${var_name}})
                file(RELATIVE_PATH _new_item ${CMAKE_SOURCE_DIR} ${_item})
                list(APPEND _new_items ${_new_item})
            endforeach()

            set(${var_name} ${_new_items})
        endif()
    endif()
endmacro()

# ----------------------------------------------------------------------
macro(_ApplyPrecompiledHeaders target_name visibility)
    if(NOT "${BUILD_PRECOMPILED_HEADERS}" STREQUAL "")
        _VerifyCmakeVersion(3.16 "Precompiled headers functionality")

        target_precompile_headers(
            ${target_name}
            ${visibility}
            ${BUILD_PRECOMPILED_HEADERS}
        )
    endif()

    if(NOT "${BUILD_PRECOMPILED_LIBRARY_HEADERS}" STREQUAL "")
        _VerifyCmakeVersion(3.16 "Precompiled headers functionality")

        target_precompile_headers(
            ${target_name}
            REUSE_FROM
            ${BUILD_PRECOMPILED_LIBRARY_HEADERS}
        )
    endif()
endmacro()

# ----------------------------------------------------------------------
macro(_VerifyCmakeVersion version desc)
    if(${CMAKE_VERSION} VERSION_LESS ${version})
        message(FATAL_ERROR "${desc} requires cmake version '${version}'; cmake version '${CMAKE_VERSION}' found.")
    endif()
endmacro()
