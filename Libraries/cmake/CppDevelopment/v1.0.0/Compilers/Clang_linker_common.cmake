# ----------------------------------------------------------------------
# |
# |  Clang_linker_common.cmake
# |
# |  David Brownell <db@DavidBrownell.com>
# |      2019-07-28 08:12:18
# |
# ----------------------------------------------------------------------
# |
# |  Copyright David Brownell 2019-22
# |  Distributed under the Boost Software License, Version 1.0. See
# |  accompanying file LICENSE_1_0.txt or copy at
# |  http://www.boost.org/LICENSE_1_0.txt.
# |
# ----------------------------------------------------------------------

# Contains linker settings common to scenarios when clang is used directly or
# as a proxy for other backend compilers (MSVC or GCC).

# ----------------------------------------------------------------------
# |  Dynamic Flags

# CppDevelopment_CODE_COVERAGE
if(WIN32 AND CMAKE_CXX_SIMULATE_ID MATCHES MSVC)
    foreach(_flag IN ITEMS
        clang_rt.profile-x86_64.lib
    )
        STRING(APPEND _EXE_LINKER_FLAGS_CppDevelopment_CODE_COVERAGE_TRUE " ${_flag}")
    endforeach()
endif()
