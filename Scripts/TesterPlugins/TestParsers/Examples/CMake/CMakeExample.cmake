include(BuildHelpers)

function(Impl)
    get_filename_component(_this_path ${CMAKE_CURRENT_LIST_FILE} DIRECTORY)

    build_library(
        NAME
            CMakeExample

        FILES
            ${_this_path}/../Add.cpp
            ${_this_path}/../Subtract.cpp

        PUBLIC_INCLUDE_DIRECTORIES
            ${_this_path}/../
    )
endfunction()

Impl()
