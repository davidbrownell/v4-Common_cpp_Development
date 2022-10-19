#pragma once

#include <stddef.h>

#if (defined _MSC_VER)
#   if (defined SHARED_OBJECT_COMPILE)
#       define SHARED_LIBRARY_API __declspec(dllexport)
#   else
#       define SHARED_LIBRARY_API __declspec(dllimport)
#   endif

#   define SHARED_LIBRARY_API_PACK_PREFIX   \
    __pragma(pack(push))                    \
    __pragma(pack(1))

#   define SHARED_LIBRARY_API_PACK_SUFFIX   __pragma(pack(pop))
#   define SHARED_LIBRARY_API_PACK_INLINE

#elif (defined __GNUC__ || defined __clang__)
#   if (defined SHARED_OBJECT_COMPILE)
#       define SHARED_LIBRARY_API __attribute__((visibility("default")))
#   else
#       define SHARED_LIBRARY_API
#   endif

#   define SHARED_LIBRARY_API_PACK_PREFIX
#   define SHARED_LIBRARY_API_PACK_SUFFIX
#   define SHARED_LIBRARY_API_PACK_INLINE   __attribute__((packed))

#else
#   error Unrecognized compiler!
#endif

extern "C" {

SHARED_LIBRARY_API_PACK_PREFIX

struct StringData {
    char const *                            pStringData;
    size_t                                  cStringData;
} SHARED_LIBRARY_API_PACK_INLINE;

SHARED_LIBRARY_API_PACK_SUFFIX

SHARED_LIBRARY_API bool InvokeFunc(StringData **ppStringData, size_t *pcStringData);
SHARED_LIBRARY_API bool DeleteStringData(StringData *pStringData, size_t cStringData);

} // extern "C"
