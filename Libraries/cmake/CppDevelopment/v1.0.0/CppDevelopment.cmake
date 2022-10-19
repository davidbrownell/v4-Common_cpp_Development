# ----------------------------------------------------------------------
# |
# |  CppDevelopment.cmake
# |
# |  David Brownell <db@DavidBrownell.com>
# |      2019-03-01 15:31:28
# |
# ----------------------------------------------------------------------
# |
# |  Copyright David Brownell 2019-22
# |  Distributed under the Boost Software License, Version 1.0. See
# |  accompanying file LICENSE_1_0.txt or copy at
# |  http://www.boost.org/LICENSE_1_0.txt.
# |
# ----------------------------------------------------------------------
cmake_minimum_required(VERSION 3.5)

cmake_policy(SET CMP0056 NEW)               # Honor link flags
cmake_policy(SET CMP0057 NEW)               # Support IN_LIST
cmake_policy(SET CMP0066 NEW)               # Honor compile flags

option(
    CppDevelopment_CMAKE_DEBUG_OUTPUT
    "Generates cmake debug output"
    OFF
)

option(
    CppDevelopment_UTF_16
    "Use the unicode character set (default is multi-byte (best practice is to leverage UTF-8))."
    OFF
)

option(
    CppDevelopment_STATIC_CRT
    "Statically link with the CRT."
    OFF
)

option(
    CppDevelopment_CODE_COVERAGE
    "Produce builds that can be used when extracting code coverage information (requires a Debug build)."
    OFF
)

option(
    CppDevelopment_NO_DEBUG_INFO
    "Do not generate debug info for the build (this is not recommended)"
    OFF
)

option(
    CppDevelopment_NO_ADDRESS_SPACE_LAYOUT_RANDOMIZATION
    "Do not generate code with Address Space Layout Randomization (ASLR). This should not be enabled unless it is not possible to compile dependencies with ASLR."
    OFF
)

option(
    CppDevelopment_PREPROCESSOR_OUTPUT
    "Generate preprocessor output"
    OFF
)

if("$ENV{DEVELOPMENT_ENVIRONMENT_CPP_CMAKE_DISABLE_PRECOMPILE_HEADERS}" STREQUAL "1")
    set(CMAKE_DISABLE_PRECOMPILE_HEADERS ON)
endif()

# CMAKE_CONFIGURATION_TYPES
set(_valid_configuration_types
    Debug                                   # Standard Debug build
    Release                                 # Release build optimizing for speed
    ReleaseMinSize                          # Release build optimizing for code size
    ReleaseNoOpt                            # Release build with no optimizations
)

if(NOT CMAKE_CONFIGURATION_TYPES)
    # Note the following changes from standard cmake:
    #   - `RelWithDebugInfo` has been removed (as it is redundant with the `CppDevelopment_NO_DEBUG_INFO` flag)
    #   - `MinSizeRel` has been renamed `ReleaseMinSize` (for consistency)
    #   - `ReleaseNoOpt` has been added
    #
    set(CMAKE_CONFIGURATION_TYPES ${_valid_configuration_types})

    set(
        CMAKE_CONFIGURATION_TYPES
        "${CMAKE_CONFIGURATION_TYPES}"
        CACHE STRING
        "Available values for CMAKE_BUILD_TYPE"
        FORCE
    )
else()
    # Some generators (like the Visual Studio generators) will specify a number of configuration
    # types. If we see these configuration types, remap them to supported values.
    if(CMAKE_CONFIGURATION_TYPES MATCHES "Debug;Release;MinSizeRel;RelWithDebInfo")
        set(CMAKE_CONFIGURATION_TYPES "Debug;Release;ReleaseMinSize;ReleaseNoOpt")
    endif()

    # Ensure that each `CMAKE_CONFIGURATION_TYPE` is valid
    foreach(_config_type IN ITEMS ${CMAKE_CONFIGURATION_TYPES})
        if(NOT(${_config_type} IN_LIST _valid_configuration_types))
            message(FATAL_ERROR "'${_config_type}' is not a supported configuration type; valid values are '${_valid_configuration_types}'")
        endif()
    endforeach()
endif()

# Ensure that `CMAKE_BUILD_TYPE` is valid
if (DEFINED CMAKE_BUILD_TYPE AND NOT CMAKE_BUILD_TYPE STREQUAL "" AND NOT ${CMAKE_BUILD_TYPE} IN_LIST CMAKE_CONFIGURATION_TYPES)
    message(FATAL_ERROR "'${CMAKE_BUILD_TYPE}' is not a supported configuration type; valid values are '${CMAKE_CONFIGURATION_TYPES}'")
endif()

# Remove configuration values that won't be used
foreach(_prefix IN ITEMS
    CMAKE_CXX_FLAGS_
    CMAKE_C_FLAGS_
    CMAKE_EXE_LINKER_FLAGS_
    CMAKE_MODULE_LINKER_FLAGS_
    CMAKE_RC_FLAGS_
    CMAKE_SHARED_LINKER_FLAGS_
    CMAKE_STATIC_LINKER_FLAGS_
)
    foreach(_configuration_type IN ITEMS
        MINSIZEREL
        RELWITHDEBINFO
    )
        unset("${_prefix}${_configuration_type}" CACHE)
    endforeach()
endforeach()

# Clear all flags
foreach(_flag_prefix IN ITEMS
    C
    CXX
    EXE_LINKER
    STATIC_LINKER
    SHARED_LINKER
    MODULE_LINKER
)
    set("CMAKE_${_flag_prefix}_FLAGS" "")
    set("_${_flag_prefix}_FLAGS" "")

    foreach(_configuration_type IN ITEMS
        DEBUG
        RELEASE
        RELEASEMINSIZE
        RELEASENOOPT
    )
        set("CMAKE_${_flag_prefix}_FLAGS_${_configuration_type}" "")
        set("_${_flag_prefix}_FLAGS_${_configuration_type}" "")
    endforeach()

    foreach(_flag_type IN ITEMS
        CppDevelopment_UTF_16
        CppDevelopment_STATIC_CRT
        CppDevelopment_CODE_COVERAGE
        CppDevelopment_NO_DEBUG_INFO
        CppDevelopment_NO_ADDRESS_SPACE_LAYOUT_RANDOMIZATION
        CppDevelopment_PREPROCESSOR_OUTPUT
    )
        set("_${_flag_prefix}_FLAGS_${_flag_type}" "")

        foreach(_boolean_type IN ITEMS
            TRUE
            FALSE
        )
            set("_${_flag_prefix}_FLAGS_${_flag_type}_${_boolean_type}" "")

            foreach(_configuration_type IN ITEMS
                DEBUG
                RELEASE
                RELEASEMINSIZE
                RELEASENOOPT
            )
                set("_${_flag_prefix}_FLAGS_${_flag_type}_${_boolean_type}_${_configuration_type}" "")
            endforeach()
        endforeach()

        foreach(_configuration_type IN ITEMS
            DEBUG
            RELEASE
            RELEASEMINSIZE
            RELEASENOOPT
        )
            set("_${_flag_prefix}_FLAGS_${_flag_type}_${_configuration_type}" "")
        endforeach()
    endforeach()
endforeach()

# ----------------------------------------------------------------------
# |
# |  Compiler- and Linker-specific Flags
# |
# ----------------------------------------------------------------------
get_filename_component(_compiler_basename "${CMAKE_CXX_COMPILER}" NAME)

if(CMAKE_CXX_COMPILER_ID MATCHES Clang)
    include(${CMAKE_CURRENT_LIST_DIR}/Compilers/Clang_compiler_common.cmake)
    include(${CMAKE_CURRENT_LIST_DIR}/Compilers/Clang_linker_common.cmake)
endif()

if(CMAKE_CXX_COMPILER_ID MATCHES MSVC OR (CMAKE_CXX_COMPILER_ID MATCHES Clang AND CMAKE_CXX_SIMULATE_ID MATCHES "MSVC"))
    include(${CMAKE_CURRENT_LIST_DIR}/Compilers/MSVC_compiler.cmake)
    include(${CMAKE_CURRENT_LIST_DIR}/Compilers/MSVC_linker.cmake)

elseif(CMAKE_CXX_COMPILER_ID MATCHES Clang)
    include(${CMAKE_CURRENT_LIST_DIR}/Compilers/Clang_compiler.cmake)
    include(${CMAKE_CURRENT_LIST_DIR}/Compilers/Clang_linker.cmake)

elseif(CMAKE_CXX_COMPILER_ID MATCHES GNU)
    include(${CMAKE_CURRENT_LIST_DIR}/Compilers/GCC_compiler.cmake)
    include(${CMAKE_CURRENT_LIST_DIR}/Compilers/GCC_linker.cmake)

else()
    message(FATAL_ERROR "The compiler '${CMAKE_CXX_COMPILER_ID}' is not supported.")

endif()

# ----------------------------------------------------------------------
# |
# |  Persist flag values
# |
# ----------------------------------------------------------------------
foreach(_flag_prefix IN ITEMS
    C
    CXX
    EXE_LINKER
    STATIC_LINKER
    SHARED_LINKER
    MODULE_LINKER
)
    set(_cmake_flag_name "CMAKE_${_flag_prefix}_FLAGS")
    set(_flag_name "_${_flag_prefix}_FLAGS")

    STRING(STRIP "${${_flag_name}}" ${_flag_name})
    set("${_cmake_flag_name}" "${${_flag_name}}" CACHE STRING "" FORCE)

    foreach(_configuration_type IN ITEMS
        DEBUG
        RELEASE
        RELEASEMINSIZE
        RELEASENOOPT
    )
        set(_cmake_flag_name "CMAKE_${_flag_prefix}_FLAGS_${_configuration_type}")
        set(_flag_name "_${_flag_prefix}_FLAGS_${_configuration_type}")

        STRING(STRIP "${${_flag_name}}" ${_flag_name})
        set("${_cmake_flag_name}" "${${_flag_name}}" CACHE STRING "" FORCE)
    endforeach()

    foreach(_flag_type IN ITEMS
        CppDevelopment_UTF_16
        CppDevelopment_STATIC_CRT
        CppDevelopment_CODE_COVERAGE
        CppDevelopment_NO_DEBUG_INFO
        CppDevelopment_NO_ADDRESS_SPACE_LAYOUT_RANDOMIZATION
        CppDevelopment_PREPROCESSOR_OUTPUT
    )
        set(_flag_name "_${_flag_prefix}_FLAGS_${_flag_type}")

        STRING(STRIP "${${_flag_name}}" ${_flag_name})
        set("${_flag_name}" "${${_flag_name}}" CACHE STRING "" FORCE)

        foreach(_boolean_type IN ITEMS
            TRUE
            FALSE
        )
            set(_flag_name "_${_flag_prefix}_FLAGS_${_flag_type}_${_boolean_type}")

            STRING(STRIP "${${_flag_name}}" ${_flag_name})
            set("${_flag_name}" "${${_flag_name}}" CACHE STRING "" FORCE)

            foreach(_configuration_type IN ITEMS
                DEBUG
                RELEASE
                RELEASEMINSIZE
                RELEASENOOPT
            )
                set(_flag_name "_${_flag_prefix}_FLAGS_${_flag_type}_${_boolean_type}_${_configuration_type}")

                STRING(STRIP "${${_flag_name}}" ${_flag_name})
                set("${_flag_name}" "${${_flag_name}}" CACHE STRING "" FORCE)
            endforeach()
        endforeach()

        foreach(_configuration_type IN ITEMS
            DEBUG
            RELEASE
            RELEASEMINSIZE
            RELEASENOOPT
        )
            set(_flag_name "_${_flag_prefix}_FLAGS_${_flag_type}_${_configuration_type}")

            STRING(STRIP "${${_flag_name}}" ${_flag_name})
            set("${_flag_name}" "${${_flag_name}}" CACHE STRING "" FORCE)
        endforeach()
    endforeach()
endforeach()

# ----------------------------------------------------------------------
# |
# |  Apply the dynamic flags
# |
# ----------------------------------------------------------------------
foreach(_flag_prefix IN ITEMS
    C
    CXX
    EXE_LINKER
    STATIC_LINKER
    SHARED_LINKER
    MODULE_LINKER
)
    foreach(_flag_type IN ITEMS
        CppDevelopment_UTF_16
        CppDevelopment_STATIC_CRT
        CppDevelopment_CODE_COVERAGE
        CppDevelopment_NO_DEBUG_INFO
        CppDevelopment_NO_ADDRESS_SPACE_LAYOUT_RANDOMIZATION
        CppDevelopment_PREPROCESSOR_OUTPUT
    )
        foreach(_boolean_type IN ITEMS
            TRUE
            FALSE
        )
            if(
                ("${_boolean_type}" MATCHES "TRUE" AND "${${_flag_type}}") OR
                ("${_boolean_type}" MATCHES "FALSE" AND NOT "${${_flag_type}}")
            )
                set(_flag_name "_${_flag_prefix}_FLAGS_${_flag_type}_${_boolean_type}")

                if(NOT "${${_flag_name}}" STREQUAL "")
                    STRING(STRIP "${${_flag_name}}" ${_flag_name})
                    STRING(APPEND CMAKE_${_flag_prefix}_FLAGS " ${${_flag_name}}")
                endif()

                foreach(_config_type IN ITEMS
                    DEBUG
                    RELEASE
                    RELEASEMINSIZE
                    RELEASENOOPT
                )
                    set(_flag_name "_${_flag_prefix}_FLAGS_${_flag_type}_${_boolean_type}_${_config_type}")

                    if(NOT "${${_flag_name}}" STREQUAL "")
                        STRING(STRIP "${${_flag_name}}" ${_flag_name})
                        STRING(APPEND CMAKE_${_flag_prefix}_FLAGS_${_config_type} " ${${_flag_name}}")
                    endif()
                endforeach()
            endif()
        endforeach()
    endforeach()
endforeach()

# ----------------------------------------------------------------------
# |
# |  Inherit default values unless explicitly provided
# |
# ----------------------------------------------------------------------
STRING(STRIP "${CMAKE_C_FLAGS}" CMAKE_C_FLAGS)

if("${CMAKE_C_FLAGS}" STREQUAL "")
    set(CMAKE_C_FLAGS ${CMAKE_CXX_FLAGS})
endif()

foreach(_configuration_type IN ITEMS
    DEBUG
    RELEASE
    RELEASEMINSIZE
    RELEASENOOPT
)
    set(_dest_flag_name "CMAKE_C_FLAGS_${_configuration_type}")
    set(_source_flag_name "CMAKE_CXX_FLAGS_${_configuration_type}")

    STRING(STRIP "${${_dest_flag_name}}" ${_dest_flag_name})

    if("${${_dest_flag_name}}" STREQUAL "")
        set(${_dest_flag_name} "${${_source_flag_name}}")
    endif()
endforeach()

foreach(_flag_prefix IN ITEMS
    SHARED_LINKER
    MODULE_LINKER
)
    set(_dest_flag_name "CMAKE_${_flag_prefix}_FLAGS")

    STRING(STRIP "${${_dest_flag_name}}" ${_dest_flag_name})

    if("${${_dest_flag_name}}" STREQUAL "")
        set(${_dest_flag_name} ${CMAKE_EXE_LINKER_FLAGS})
    endif()

    foreach(_configuration_type IN ITEMS
        DEBUG
        RELEASE
        RELEASEMINSIZE
        RELEASENOOPT
    )
        set(_dest_flag_name "CMAKE_${_flag_prefix}_FLAGS_${_configuration_type}")
        set(_source_flag_name "CMAKE_EXE_LINKER_FLAGS_${_configuration_type}")

        STRING(STRIP "${${_dest_flag_name}}" ${_dest_flag_name})

        if("${${_dest_flag_name}}" STREQUAL "")
            set(${_dest_flag_name} ${${_source_flag_name}})
        endif()
    endforeach()
endforeach()

# Flags have been verified for:
#   - MSVC
#   - Clang (Windows using MSVC)
#   - Clang (Linux)
#   - GCC (Linux)

# Grab default flags from the environment
STRING(APPEND CMAKE_C_FLAGS " $ENV{CFLAGS}")
STRING(APPEND CMAKE_CXX_FLAGS " $ENV{CXXFLAGS}")
STRING(APPEND CMAKE_EXE_LINKER_FLAGS " $ENV{LDFLAGS}")
STRING(APPEND CMAKE_STATIC_LINKER_FLAGS " $ENV{STATICLIB_LDFLAGS}")
STRING(APPEND CMAKE_SHARED_LINKER_FLAGS " $ENV{SHLIB_LDFLAGS}")
STRING(APPEND CMAKE_MODULE_LINKER_FLAGS " $ENV{MODULE_LDFLAGS}")

if(${CppDevelopment_CMAKE_DEBUG_OUTPUT})
    # Output the results
    message(STATUS "")
    message(STATUS "CXXFLAGS:                           $ENV{CXXFLAGS}")
    message(STATUS "CMAKE_CXX_FLAGS:                    ${CMAKE_CXX_FLAGS}")
    message(STATUS "CMAKE_CXX_FLAGS_DEBUG:              ${CMAKE_CXX_FLAGS_DEBUG}")
    message(STATUS "CMAKE_CXX_FLAGS_RELEASE:            ${CMAKE_CXX_FLAGS_RELEASE}")
    message(STATUS "CMAKE_CXX_FLAGS_RELEASEMINSIZE:     ${CMAKE_CXX_FLAGS_RELEASEMINSIZE}")
    message(STATUS "CMAKE_CXX_FLAGS_RELEASENOOPT:       ${CMAKE_CXX_FLAGS_RELEASENOOPT}")
    message(STATUS "")
    message(STATUS "CFLAGS:                             $ENV{CFLAGS}")
    message(STATUS "CMAKE_C_FLAGS:                      ${CMAKE_C_FLAGS}")
    message(STATUS "CMAKE_C_FLAGS_DEBUG:                ${CMAKE_C_FLAGS_DEBUG}")
    message(STATUS "CMAKE_C_FLAGS_RELEASE:              ${CMAKE_C_FLAGS_RELEASE}")
    message(STATUS "CMAKE_C_FLAGS_RELEASEMINSIZE:       ${CMAKE_C_FLAGS_RELEASEMINSIZE}")
    message(STATUS "CMAKE_C_FLAGS_RELEASENOOPT:         ${CMAKE_C_FLAGS_RELEASENOOPT}")
    message(STATUS "")
    message(STATUS "LDFLAGS:                                    $ENV{LDFLAGS}")
    message(STATUS "CMAKE_EXE_LINKER_FLAGS:                     ${CMAKE_EXE_LINKER_FLAGS}")
    message(STATUS "CMAKE_EXE_LINKER_FLAGS_DEBUG:               ${CMAKE_EXE_LINKER_FLAGS_DEBUG}")
    message(STATUS "CMAKE_EXE_LINKER_FLAGS_RELEASE:             ${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
    message(STATUS "CMAKE_EXE_LINKER_FLAGS_RELEASEMINSIZE:      ${CMAKE_EXE_LINKER_FLAGS_RELEASEMINSIZE}")
    message(STATUS "CMAKE_EXE_LINKER_FLAGS_RELEASENOOPT:        ${CMAKE_EXE_LINKER_FLAGS_RELEASENOOPT}")
    message(STATUS "")
    message(STATUS "STATICLIB_LDFLAGS:                          $ENV{STATICLIB_LDFLAGS}")
    message(STATUS "CMAKE_STATIC_LINKER_FLAGS:                  ${CMAKE_STATIC_LINKER_FLAGS}")
    message(STATUS "CMAKE_STATIC_LINKER_FLAGS_DEBUG:            ${CMAKE_STATIC_LINKER_FLAGS_DEBUG}")
    message(STATUS "CMAKE_STATIC_LINKER_FLAGS_RELEASE:          ${CMAKE_STATIC_LINKER_FLAGS_RELEASE}")
    message(STATUS "CMAKE_STATIC_LINKER_FLAGS_RELEASEMINSIZE:   ${CMAKE_STATIC_LINKER_FLAGS_RELEASEMINSIZE}")
    message(STATUS "CMAKE_STATIC_LINKER_FLAGS_RELEASENOOPT:     ${CMAKE_STATIC_LINKER_FLAGS_RELEASENOOPT}")
    message(STATUS "")
    message(STATUS "SHLIB_LDFLAGS:                              $ENV{SHLIB_LDFLAGS}")
    message(STATUS "CMAKE_SHARED_LINKER_FLAGS:                  ${CMAKE_SHARED_LINKER_FLAGS}")
    message(STATUS "CMAKE_SHARED_LINKER_FLAGS_DEBUG:            ${CMAKE_SHARED_LINKER_FLAGS_DEBUG}")
    message(STATUS "CMAKE_SHARED_LINKER_FLAGS_RELEASE:          ${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
    message(STATUS "CMAKE_SHARED_LINKER_FLAGS_RELEASEMINSIZE:   ${CMAKE_SHARED_LINKER_FLAGS_RELEASEMINSIZE}")
    message(STATUS "CMAKE_SHARED_LINKER_FLAGS_RELEASENOOPT:     ${CMAKE_SHARED_LINKER_FLAGS_RELEASENOOPT}")
    message(STATUS "")
    message(STATUS "MODULE_LDFLAGS:                             $ENV{MOUDLE_LDFLAGS}")
    message(STATUS "CMAKE_MODULE_LINKER_FLAGS:                  ${CMAKE_MODULE_LINKER_FLAGS}")
    message(STATUS "CMAKE_MODULE_LINKER_FLAGS_DEBUG:            ${CMAKE_MODULE_LINKER_FLAGS_DEBUG}")
    message(STATUS "CMAKE_MODULE_LINKER_FLAGS_RELEASE:          ${CMAKE_MODULE_LINKER_FLAGS_RELEASE}")
    message(STATUS "CMAKE_MODULE_LINKER_FLAGS_RELEASEMINSIZE:   ${CMAKE_MODULE_LINKER_FLAGS_RELEASEMINSIZE}")
    message(STATUS "CMAKE_MODULE_LINKER_FLAGS_RELEASENOOPT:     ${CMAKE_MODULE_LINKER_FLAGS_RELEASENOOPT}")
    message(STATUS "")
    message(STATUS "***** CMAKE_BUILD_TYPE: '${CMAKE_BUILD_TYPE}' *****")
    message(STATUS "")
endif()
