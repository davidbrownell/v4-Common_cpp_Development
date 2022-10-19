#if __clang__
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wpadded"
#endif

#include <catch2/catch_test_macros.hpp>

#if __clang__
    #pragma clang diagnostic pop
#endif

#include "Subtract.h"

TEST_CASE("TestA") {
    CHECK(Subtract(10, 3) == 7);
}

TEST_CASE("TestB") {
    CHECK(Subtract(1, 14) == -13);
}
