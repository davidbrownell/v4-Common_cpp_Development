# LocalEndToEndTestsImpl

This folder contains tests that exercise the CMake functionality found in `../`. However, these
tests are named in such a way that they are disabled (as we can't be sure that there is a C++
compiler available when this repository is activated).

Repositories that rely on this functionality should create tests that invoke the scripts in this
directory to properly test this generic CMake functionality.
