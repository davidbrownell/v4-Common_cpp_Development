# ----------------------------------------------------------------------
# |
# |  GCC_compiler.cmake
# |
# |  David Brownell <db@DavidBrownell.com>
# |      2019-09-26 16:30:48
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

# Specific warnings are based off of recommendations at https://github.com/cpp-best-practices/cppbestpractices/blob/master/02-Use_the_Tools_Available.md?utm_source=pocket_mylist#gcc--clang

foreach(_flag IN ITEMS
    -fasynchronous-unwind-tables            # Increased reliability of backtraces
    -fexceptions                            # Enable table-based thread cancellation
    -fvisibility=hidden                     # Symbols in shared libraries are hidden by default (which is consistent with Windows)
    -pedantic
    -pipe                                   # Avoid temporary files
    -pthread                                # Thread functionality
    -W
    -Wall                                   # All warnings
    -Werror                                 # Treat warnings as errors
    -Wextra
    -Wl,-rpath,'\\\$ORIGIN'                 # Look for libs in the same dir
    -Wno-unused-local-typedefs

    # Opt-in to specific warnings
    -Wcast-align                            # warn for potential performance problem casts
    -Wconversion                            # warn on type conversions that may lose data
    -Wdouble-promotion                      # (GCC >= 4.6, Clang >= 3.8) warn if float is implicitly promoted to double
    -Wduplicated-cond                       # (only in GCC >= 6.0) warn if if / else chain has duplicated conditions
    -Wduplicated-branches                   # (only in GCC >= 7.0) warn if if / else branches have duplicated code
    -Wformat=2                              # warn on security issues around functions that format output (i.e., printf)
    -Wimplicit-fallthrough                  # Warns when case statements fall-through. (Included with -Wextra in GCC, not in clang)
    -Wmisleading-indentation                # (only in GCC >= 6.0) warn if indentation implies blocks where blocks do not exist
    -Wlogical-op                            # (only in GCC) warn about logical operations being used where bitwise were probably wanted
    -Wnon-virtual-dtor                      # warn the user if a class with virtual functions has a non-virtual destructor. This helps catch hard to track down memory errors
    -Wnull-dereference                      # (only in GCC >= 6.0) warn if a null dereference is detected
    -Wold-style-cast                        # warn for c-style casts
    -Woverloaded-virtual                    # warn if you overload (not override) a virtual function
    -Wpedantic                              # (all versions of GCC, Clang >= 3.2) warn if non-standard C++ is used
    -Wshadow                                # warn the user if a variable declaration shadows one from a parent context
    -Wsign-conversion                       # (Clang all versions, GCC >= 4.3) warn on sign conversions
    -Wunused                                # warn on anything being unused
    -Wuseless-cast                          # (only in GCC >= 4.8) warn if you perform a cast to the same type
)
    STRING(APPEND _CXX_FLAGS " ${_flag}")
endforeach()

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
    -Wl,-z,defs                             # Detect and reject underlinking
    -Wl,-z,now                              # Disable lazy binding
    -Wl,-z,relro                            # Read-only segments after relocation
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
    -Wl,-z,defs                             # Detect and reject underlinking
    -Wl,-z,now                              # Disable lazy binding
    -Wl,-z,relro                            # Read-only segments after relocation
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
    -Wl,-z,defs                             # Detect and reject underlinking
    -Wl,-z,now                              # Disable lazy binding
    -Wl,-z,relro                            # Read-only segments after relocation
)
    STRING(APPEND _CXX_FLAGS_RELEASENOOPT " ${_flag}")
endforeach()

if("$ENV{DEVELOPMENT_ENVIRONMENT_CPP_ARCHITECTURE}" MATCHES "x64")
    STRING(APPEND _CXX_FLAGS " -m64")
elseif("$ENV{DEVELOPMENT_ENVIRONMENT_CPP_ARCHITECTURE}" MATCHES "x86")
    STRING(APPEND _CXX_FLAGS " -m32")
else()
    message(FATAL_ERROR "'$ENV{DEVELOPMENT_ENVIRONMENT_CPP_ARCHITECTURE}' is not recognized")
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

# CppDevelopment_CODE_COVERAGE
foreach(_flag IN ITEMS
    --coverage
)
    STRING(APPEND _CXX_FLAGS_CppDevelopment_CODE_COVERAGE_TRUE " ${_flag}")
endforeach()
