#if __clang__
    #pragma clang diagnostic push

    #pragma clang diagnostic ignored "-Wcovered-switch-default"
    #pragma clang diagnostic ignored "-Wdocumentation-unknown-command"
    #pragma clang diagnostic ignored "-Wdouble-promotion"
    #pragma clang diagnostic ignored "-Wimplicit-int-float-conversion"
    #pragma clang diagnostic ignored "-Wnonportable-system-include-path"
    #pragma clang diagnostic ignored "-Wpadded"
    #pragma clang diagnostic ignored "-Wsign-conversion"
    #pragma clang diagnostic ignored "-Wswitch-enum"
    #pragma clang diagnostic ignored "-Wunused-but-set-variable"

#elif (defined _MSC_VER)
    #pragma warning(push)
    #pragma warning(disable: 4324) // structure was padded due to alignment specifier
#endif

#define CATCH_CONFIG_CONSOLE_WIDTH 200
#include <catch2/extras/catch_amalgamated.cpp>

#if __clang__
    #pragma clang diagnostic pop
#elif (defined _MSC_VER)
    #pragma warning(pop)
#endif

#include "shared.h"

TEST_CASE("Standard") {
    StringData *                            pStringData(nullptr);
    size_t                                  cStringData(0);

    CHECK(InvokeFunc(&pStringData, &cStringData));
    REQUIRE(pStringData != nullptr);
    REQUIRE(cStringData == 3);

    CHECK(strcmp(pStringData[0].pStringData, "one") == 0);
    CHECK(pStringData[0].cStringData == 3);

    CHECK(strcmp(pStringData[1].pStringData, "two") == 0);
    CHECK(pStringData[1].cStringData == 3);

    CHECK(strcmp(pStringData[2].pStringData, "three") == 0);
    CHECK(pStringData[2].cStringData == 5);

    CHECK(DeleteStringData(pStringData, cStringData));
}
