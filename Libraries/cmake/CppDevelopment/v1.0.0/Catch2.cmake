# ----------------------------------------------------------------------
# |
# |  Catch2.cmake
# |
# |  David Brownell <db@DavidBrownell.com>
# |      2022-10-11 10:45:20
# |
# ----------------------------------------------------------------------
# |
# |  Copyright David Brownell 2022
# |  Distributed under the Boost Software License, Version 1.0. See
# |  accompanying file LICENSE_1_0.txt or copy at
# |  http://www.boost.org/LICENSE_1_0.txt.
# |
# ----------------------------------------------------------------------
cmake_minimum_required(VERSION 3.5)

# Usage:
#
#     include(Catch2)
#
#     <more content here>
#
#     build_tests(
#         FILES
#             <files here>
#
#         LINK_LIBRARIES
#             Catch2::Catch2WithMain
#     )

# Include the Catch2 library
add_subdirectory("$ENV{DEVELOPMENT_ENVIRONMENT_CMAKE_CATCH2_ROOT}" Catch2)

# Disable warnings that prevent compilation
if(CMAKE_CXX_COMPILER_ID MATCHES Clang)
    target_compile_options(
        Catch2
        PRIVATE
        -Wno-covered-switch-default
        -Wno-documentation-unknown-command
        -Wno-double-promotion
        -Wno-implicit-int-float-conversion
        -Wno-nonportable-system-include-path
        -Wno-padded
        -Wno-sign-conversion
        -Wno-switch-enum
        -Wno-unused-but-set-variable
    )

    target_compile_options(
        Catch2WithMain
        PRIVATE
        -Wno-covered-switch-default
        -Wno-documentation-unknown-command
        -Wno-double-promotion
        -Wno-implicit-int-float-conversion
        -Wno-nonportable-system-include-path
        -Wno-padded
        -Wno-sign-conversion
        -Wno-switch-enum
        -Wno-unused-but-set-variable
    )
elseif (CMAKE_CXX_COMPILER_ID MATCHES MSVC)
    target_compile_options(
        Catch2
        PRIVATE
        /wd4324
    )

    target_compile_options(
        Catch2WithMain
        PRIVATE
        /wd4324
    )
endif()
