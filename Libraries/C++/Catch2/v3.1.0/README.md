There are 2 different ways to consume this content with examples for each technique.

## CMake-centric

Use cmake to identify and compile the libraries needed to link with Catch2. This is the new (and
preferred) way to interact with Catch2, but has a hard-dependency on CMake (which may be overkill
for very small projects).

Example: [../../../../Scripts/TesterPlugins/TestParsers/Examples/UnitTests/CMakeLists.txt](../../../../Scripts/TesterPlugins/TestParsers/Examples/UnitTests/CMakeLists.txt).

## Via Preprocessor

Use the preprocessor to include Catch2 content. This is the older way to interact with Catch2 but
results in slower build times.

Example: [../../../cmake/CppDevelopment/v1.0.0/LocalEndToEndTestsImpl/exe.cpp](../../../cmake/CppDevelopment/v1.0.0/LocalEndToEndTestsImpl/exe.cpp).
