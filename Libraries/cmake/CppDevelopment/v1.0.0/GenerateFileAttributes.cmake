# ----------------------------------------------------------------------
# |
# |  GenerateFileAttributes.cmake
# |
# |  David Brownell <db@DavidBrownell.com>
# |      2019-10-16 10:51:37
# |
# ----------------------------------------------------------------------
# |
# |  Copyright David Brownell 2019
# |  Distributed under the Boost Software License, Version 1.0. See
# |  accompanying file LICENSE_1_0.txt or copy at
# |  http://www.boost.org/LICENSE_1_0.txt.
# |
# ----------------------------------------------------------------------

# This code is based on code by halex2005, available at https://github.com/halex2005/CMakeHelpers/blob/master/generate_product_version.cmake,
# which is distributed under the MIT license (https://github.com/halex2005/CMakeHelpers/blob/master/LICENSE).

include(CMakeParseArguments)

set(_generate_file_attributes_this_dir ${CMAKE_CURRENT_LIST_DIR} CACHE INTERNAL "")

function(generate_file_attributes outfiles)
    # Parse the arguments
    set(options)
    set(single_value_args
        NAME                                # Name of the file
        COMPANY_NAME                        # Company name associated with the file

        VERSION_MAJOR                       # Semantic version major value ('1' in the version 1.2.3-alpha2+201910161219)
        VERSION_MINOR                       # Semantic version minor value ('2' in the version 1.2.3-alpha2+201910161219)
        VERSION_PATCH                       # Optional Semantic version patch value, defaults to '0' ('3' in the version 1.2.3-alpha2+201910161219)
        VERSION_PRERELEASE_INFO             # Optional Semantic version prerelease value, defaults to '' ('alpha2' in the version 1.2.3-alpha2+201910161219)
        VERSION_BUILD_INFO                  # Optional Semantic version build info, defaults to '' ('201910161219' in the version 1.2.3-alpha2+201910161219)

        FILE_DESCRIPTION                    # Optional, defaults to "${NAME}"
        BUNDLE                              # Optional product name, defaults to "${NAME}"
        ICON                                # Optional icon filename, defaults to "${CMAKE_SOURCE_DIR}/product.ico"
        COPYRIGHT                           # Optional copyright, defaults to "${NAME} (C) Copyright ${CURRENT_YEAR}"
        COMMENTS                            # Optional comments for the file, defaults to "${NAME} v${VERSION_MAJOR}.${VERSION_MINOR}"
        ORIGINAL_FILENAME                   # Optional, defaults to "${NAME}"
        INTERNAL_NAME                       # Optional, defaults to "${NAME}"
    )
    set(multi_value_args)

    cmake_parse_arguments(
        PRODUCT
        "${options}"
        "${single_value_args}"
        "${multi_value_args}"
        ${ARGN}
    )

    # Validate required values
    foreach(_arg IN ITEMS
        PRODUCT_NAME
        PRODUCT_COMPANY_NAME
        PRODUCT_VERSION_MAJOR
        PRODUCT_VERSION_MINOR
    )
        if("${${_arg}}" STREQUAL "")
            MESSAGE(FATAL_ERROR "'${_arg}' is a required parameter")
        endif()
    endforeach()

    # Set defaults
    if(NOT PRODUCT_VERSION_PATCH OR "${PRODUCT_VERSION_PATCH}" STREQUAL "")
        set(PRODUCT_VERSION_PATCH "0")
    endif()

    if(NOT PRODUCT_VERSION_PRERELEASE_INFO OR "${PRODUCT_VERSION_PRERELEASE_INFO}" STREQUAL "")
        set(PRODUCT_VERSION_PRERELEASE_INFO "")
    else()
        set(PRODUCT_VERSION_PRERELEASE_INFO "-${PRODUCT_VERSION_PRERELEASE_INFO}")
    endif()

    if(NOT PRODUCT_VERSION_BUILD_INFO OR "${PRODUCT_VERSION_BUILD_INFO}" STREQUAL "")
        set(PRODUCT_VERSION_BUILD_INFO "")
    else()
        set(PRODUCT_VERSION_BUILD_INFO "+${PRODUCT_VERSION_BUILD_INFO}")
    endif()

    if (NOT PRODUCT_FILE_DESCRIPTION OR "${PRODUCT_FILE_DESCRIPTION}" STREQUAL "")
        set(PRODUCT_FILE_DESCRIPTION "${PRODUCT_NAME}")
    endif()

    if(NOT PRODUCT_BUNDLE OR "${PRODUCT_BUNDLE}" STREQUAL "")
        set(PRODUCT_BUNDLE "${PRODUCT_NAME}")
    endif()

    if(NOT PRODUCT_ICON OR "${PRODUCT_ICON}" STREQUAL "")
        set(PRODUCT_ICON "product.ico")
    endif()

    if(NOT PRODUCT_COPYRIGHT OR "${PRODUCT_COPYRIGHT}" STREQUAL "")
        string(TIMESTAMP PRODUCT_CURRENT_YEAR "%Y")
        set(PRODUCT_COPYRIGHT "${PRODUCT_COMPANY_NAME} (C) Copyright ${PRODUCT_CURRENT_YEAR}")
    endif()

    if(NOT PRODUCT_COMMENTS OR "${PRODUCT_COMMENTS}" STREQUAL "")
        set(PRODUCT_COMMENTS "${PRODUCT_NAME} v${PRODUCT_VERSION_MAJOR}.${PRODUCT_VERSION_MINOR}")
    endif()

    if(NOT PRODUCT_ORIGINAL_FILENAME OR "${PRODUCT_ORIGINAL_FILENAME}" STREQUAL "")
        set(PRODUCT_ORIGINAL_FILENAME "${PRODUCT_NAME}")
    endif()

    if(NOT PRODUCT_INTERNAL_NAME OR "${PRODUCT_INTERNAL_NAME}" STREQUAL "")
        set(PRODUCT_INTERNAL_NAME "${PRODUCT_NAME}")
    endif()

    MESSAGE(STATUS_MESSAGE "\n\nProduct version for '${PRODUCT_NAME}' is '${PRODUCT_VERSION_MAJOR}.${PRODUCT_VERSION_MINOR}.${PRODUCT_VERSION_PATCH}${PRODUCT_VERSION_PRERELEASE_INFO}${PRODUCT_VERSION_BUILD_INFO}'\n\n")

    # Apply
    set(PRODUCT_VERSION_SUFFIX "${PRODUCT_VERSION_PRERELEASE_INFO}${PRODUCT_VERSION_BUILD_INFO}")

    set(_header_filename ${CMAKE_CURRENT_BINARY_DIR}/${PRODUCT_NAME}.FileAttributes.h)
    set(_resource_filename ${CMAKE_CURRENT_BINARY_DIR}/${PRODUCT_NAME}.FileAttributes.rc)

    configure_file(
        ${_generate_file_attributes_this_dir}/FileAttributes/FileAttributes.in.json
        ${CMAKE_CURRENT_BINARY_DIR}/${PRODUCT_NAME}.FileAttributes.json
        @ONLY
    )

    configure_file(
        ${_generate_file_attributes_this_dir}/FileAttributes/FileAttributes.in.h
        ${_header_filename}
        @ONLY
    )

    configure_file(
        ${_generate_file_attributes_this_dir}/FileAttributes/FileAttributes.in.rc
        ${_resource_filename}
        @ONLY
    )

    list(APPEND ${outfiles} ${_header_filename} ${_resource_filename})
    set(${outfiles} ${${outfiles}} PARENT_SCOPE)
endfunction()
