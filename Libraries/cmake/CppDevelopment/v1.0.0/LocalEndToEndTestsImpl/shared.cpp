#define SHARED_OBJECT_COMPILE
#include "shared.h"

#include <cstring>                          // For memcpy
#include <memory>                           // For std::unique_ptr

#include "lib.h"

extern "C" {

SHARED_LIBRARY_API bool InvokeFunc(StringData **ppStringData, size_t *pcStringData) {
    // ----------------------------------------------------------------------
    struct Internal {
        static void StringDataDeleter(char *pData) {
            delete [] pData;
        }

        static void StringDataVectorDeleter(StringData *pData) {
            delete [] pData;
        }
    };

    using StringDataUniquePtr               = std::unique_ptr<char, void (*)(char *)>;
    using StringDataVector                  = std::vector<std::tuple<StringDataUniquePtr, size_t>>;
    using StringDataElementsUniquePtr       = std::unique_ptr<StringData, void (*)(StringData *)>;
    // ----------------------------------------------------------------------

    if(ppStringData == nullptr || pcStringData == nullptr)
        return false;

    *ppStringData = nullptr;
    *pcStringData = 0;

    std::vector<std::string> const          results(Func());
    StringDataVector                        allStringData;

    allStringData.reserve(results.size());

    for(auto const &result : results) {
        StringDataUniquePtr                 pRawString(new char[result.size() + 1], Internal::StringDataDeleter);

        memcpy(pRawString.get(), result.c_str(), result.size() + 1);

        allStringData.emplace_back(std::move(pRawString), result.size());
    }

    StringDataElementsUniquePtr             pAllStringData(new StringData[allStringData.size()], Internal::StringDataVectorDeleter);
    StringData *                            pAllStringDataElement(pAllStringData.get());

    for(auto &stringData : allStringData) {
        pAllStringDataElement->pStringData = std::get<0>(stringData).get();
        pAllStringDataElement->cStringData = std::get<1>(stringData);
        ++pAllStringDataElement;
    }

    // If here, everything was successful and we can release all smart pointers
    for(auto &stringData : allStringData)
        std::get<0>(stringData).release();

    *ppStringData = pAllStringData.release();
    *pcStringData = allStringData.size();

    return true;
}

SHARED_LIBRARY_API bool DeleteStringData(StringData *pStringData, size_t cStringData) {
    if(pStringData == nullptr || cStringData == 0)
        return false;

    StringData *                            ptr(pStringData);
    StringData const * const                pEnd(pStringData + cStringData);

    while(ptr != pEnd) {
        StringData &                        data(*ptr++);

        if(data.pStringData == nullptr || data.cStringData == 0)
            return false;

        delete [] data.pStringData;
    }

    delete [] pStringData;
    return true;
}

} // extern "C"
