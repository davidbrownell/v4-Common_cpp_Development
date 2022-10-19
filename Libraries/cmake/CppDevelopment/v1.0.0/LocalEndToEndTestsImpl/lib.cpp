#include "lib.h"

std::vector<std::string> Func(void) {
    std::vector<std::string>                results{ "one", "two" };

    // Emplacement has been a problem with some systems (such as the docker image
    // phusion/holy-build-box-64).
    {
        std::string                         value("three");

        results.emplace_back(std::move(value));
    }

    return results;
}
