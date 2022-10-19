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

#include "lib.h"

TEST_CASE("Standard") {
    CHECK(Func() == std::vector<std::string>{"one", "two", "three"});
}
