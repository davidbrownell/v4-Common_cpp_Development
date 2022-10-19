# ----------------------------------------------------------------------
# |
# |  MSVC_linker.cmake
# |
# |  David Brownell <db@DavidBrownell.com>
# |      2019-07-28 09:08:30
# |
# ----------------------------------------------------------------------
# |
# |  Copyright David Brownell 2019-22
# |  Distributed under the Boost Software License, Version 1.0. See
# |  accompanying file LICENSE_1_0.txt or copy at
# |  http://www.boost.org/LICENSE_1_0.txt.
# |
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# |  Static Flags
foreach(_flag IN ITEMS
    /DYNAMICBASE                                        # Randomized base address
    /MANIFEST                                           # Creates a side-by-side manifest file and optionally embeds it in the binary.
    /NXCOMPAT                                           # Data Execution Prevention
    /MANIFESTUAC:"level='asInvoker' uiAccess='false'"   # Specifies whether User Account Control (UAC) information is embedded in the program manifest.
    /TLBID:1                                            # Specifies the resource ID of the linker-generated type library.
)
    STRING(APPEND _EXE_LINKER_FLAGS " ${_flag}")
endforeach()

# The following flags are valid for MSVC but not for Clang
if(CMAKE_CXX_COMPILER_ID MATCHES MSVC)
    foreach(_flag IN ITEMS
        /LTCG                               # Link-time code generation
    )
        STRING(APPEND _EXE_LINKER_FLAGS_RELEASE " ${_flag}")
    endforeach()
endif()

# The following flags are valid for both MSVC and Clang
foreach(_flag IN ITEMS
    /OPT:ICF                                # Enable COMDAT Folding
    /OPT:REF                                # References
)
    STRING(APPEND _EXE_LINKER_FLAGS_RELEASE " ${_flag}")
endforeach()

set(_EXE_LINKER_FLAGS_RELEASEMINSIZE "${_EXE_LINKER_FLAGS_RELEASE}")
set(_EXE_LINKER_FLAGS_RELEASENOOPT "${_EXE_LINKER_FLAGS_RELEASE}")

# ----------------------------------------------------------------------
# |  Dynamic Flags

# CppDevelopment_CODE_COVERAGE
foreach(_flag IN ITEMS
    /PROFILE
    /OPT:NOREF
    /OPT:NOICF
)
    STRING(APPEND _EXE_LINKER_FLAGS_CppDevelopment_CODE_COVERAGE_TRUE " ${_flag}")
endforeach()

set(_EXE_LINKER_FLAGS_CppDevelopment_CODE_COVERAGE_FALSE_DEBUG "/INCREMENTAL")
set(_EXE_LINKER_FLAGS_CppDevelopment_CODE_COVERAGE_FALSE_RELEASE "/INCREMENTAL:NO")

# CppDevelopment_NO_DEBUG_INFO
set(_EXE_LINKER_FLAGS_CppDevelopment_NO_DEBUG_INFO_FALSE "/DEBUG")
