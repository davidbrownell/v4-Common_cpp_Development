cmake_minimum_required(VERSION 3.5.0)

# All paths should be relative to `${_this_path}`.
get_filename_component(_this_path ${CMAKE_CURRENT_LIST_FILE} DIRECTORY)

include(${_this_path}/shared.cmake)
