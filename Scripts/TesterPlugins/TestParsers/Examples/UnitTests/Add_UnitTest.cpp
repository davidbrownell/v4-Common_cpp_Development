#if __clang__
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wpadded"
#endif

#include <catch2/catch_test_macros.hpp>
#include <catch2/benchmark/catch_benchmark.hpp>

#if __clang__
    #pragma clang diagnostic pop
#endif

#include "Add.h"

TEST_CASE("Test1") {
    CHECK(Add(10, 3) == 13);
}

TEST_CASE("Test2") {
    CHECK(Add(1, 14) == 15);
}

void Benchmark() {
    REQUIRE(Add(10, 20) == 30);
}

TEST_CASE("Benchmark", "[benchmark]") {
    BENCHMARK("Add benchmark") { Benchmark(); };
}
