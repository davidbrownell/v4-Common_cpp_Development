# ----------------------------------------------------------------------
# |
# |  Clang_compiler.cmake
# |
# |  David Brownell <db@DavidBrownell.com>
# |      2019-07-28 09:11:21
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
    -fasynchronous-unwind-tables            # Increased reliability of backtraces
    -fexceptions                            # Enable table-based thread cancellation
    -fvisibility=hidden                     # Symbols in shared libraries are hidden by default (which is consistent with Windows)
    -pedantic
    -pipe                                   # Avoid temporary files
    -pthread                                # Thread functionality
)
    STRING(APPEND _CXX_FLAGS " ${_flag}")
endforeach()

if(NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS 10.0.0)
    foreach(_flag IN ITEMS
        -Wno-misleading-indentation
    )
        STRING(APPEND _CXX_FLAGS " ${_flag}")
    endforeach()
endif()

# Debug
foreach(_flag IN ITEMS
    -DDEBUG
    -D_DEBUG
    -O0                                     # No optimizations
)
    STRING(APPEND _CXX_FLAGS_DEBUG " ${_flag}")
endforeach()

# Release args
foreach(_flag IN ITEMS
    -DNDEBUG
    -D_NDEBUG
    -D_FORTIFY_SOURCE=2                     # Run-time buffer overflow detection
    -D_GLIBCXX_ASSERTIONS                   # Run-time bounds checking for C++ strings and containers
    -fstack-protector-strong                # Stack smashing protection
    -O3                                     # Advanced optimizations
)
    STRING(APPEND _CXX_FLAGS_RELEASE " ${_flag}")
endforeach()

# ReleaseMinSize
foreach(_flag IN ITEMS
    -DNDEBUG
    -D_NDEBUG
    -D_FORTIFY_SOURCE=2                     # Run-time buffer overflow detection
    -D_GLIBCXX_ASSERTIONS                   # Run-time bounds checking for C++ strings and containers
    -fstack-protector-strong                # Stack smashing protection
    -Os                                     # Optimize for small code
)
    STRING(APPEND _CXX_FLAGS_RELEASEMINSIZE " ${_flag}")
endforeach()

# ReleaseNoOpt
foreach(_flag IN ITEMS
    -DNDEBUG
    -D_NDEBUG
    -D_FORTIFY_SOURCE=2                     # Run-time buffer overflow detection
    -D_GLIBCXX_ASSERTIONS                   # Run-time bounds checking for C++ strings and containers
    -fstack-protector-strong                # Stack smashing protection
    -O0                                     # No optimizations
)
    STRING(APPEND _CXX_FLAGS_RELEASENOOPT " ${_flag}")
endforeach()

if(APPLE)
    # Do not add additional flags
else()
    # On Windows, the mingw-version of clang struggles with some flags (could this be a bug?).
    if(NOT WIN32 OR CMAKE_CXX_SIMULATE_ID MATCHES "MSVC")
        foreach(_flag IN ITEMS
            -Wl,-rpath,'\\\$ORIGIN'         # Look for libs in the same dir
        )
            STRING(APPEND _CXX_FLAGS " ${_flag}")
        endforeach()

        foreach(_dest_flag IN ITEMS
            _CXX_FLAGS_RELEASE
            _CXX_FLAGS_RELEASEMINSIZE
            _CXX_FLAGS_RELEASENOOPT
        )
            foreach(_flag IN ITEMS
                -Wl,-z,defs                 # Detect and reject underlinking
                -Wl,-z,now                  # Disable lazy binding
                -Wl,-z,relro                # Read-only segments after relocation
            )
                STRING(APPEND ${_dest_flag} " ${_flag}")
            endforeach()
        endforeach()
    endif()
endif()

# ----------------------------------------------------------------------
# |  Dynamic Flags

# CppDevelopment_UTF_16
set(_CXX_FLAGS_CppDevelopment_UTF_16_TRUE "-DUNICODE -D_UNICODE")
set(_CXX_FLAGS_CppDevelopment_UTF_16_FALSE "-DMBCS -D_MBCS")

# CppDevelopment_STATIC_CRT
set(_CXX_FLAGS_CppDevelopment_STATIC_CRT_TRUE "-static-libstdc++")

# CppDevelopment_NO_DEBUG_INFO
foreach(_flag IN ITEMS
    -g                                      # Generate debugging information
    -grecord-gcc-switches                   # Store compiler flags in debugging information
)
    STRING(APPEND _CXX_FLAGS_CppDevelopment_NO_DEBUG_INFO_FALSE " ${_flag}")
endforeach()

# CppDevelopment_NO_ADDRESS_SPACE_LAYOUT_RANDOMIZATION
set(_CXX_FLAGS_CppDevelopment_NO_ADDRESS_SPACE_LAYOUT_RANDOMIZATION_FALSE "-fPIC")
set(_EXE_LINKER_FLAGS_CppDevelopment_NO_ADDRESS_SPACE_LAYOUT_RANDOMIZATION_FALSE "-pie")

# CppDevelopment_PREPROCESSOR_OUTPUT
set(_CXX_FLAGS_CppDevelopment_PREPROCESSOR_OUTPUT_TRUE "-E")
