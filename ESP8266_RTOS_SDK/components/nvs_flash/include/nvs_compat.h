/*
 * Compatibility header for ESP8266 RTOS SDK
 * Provides cstdint compatibility for older toolchains
 */

#ifndef NVS_COMPAT_H
#define NVS_COMPAT_H

#ifdef __cplusplus
extern "C" {
#endif

// Include stdint.h for C compatibility
#include <stdint.h>

// For C++ code, provide cstdint-like definitions
#ifdef __cplusplus
    // These should already be defined by stdint.h
    // but we ensure they're available for C++
    using std::uint8_t;
    using std::uint16_t;
    using std::uint32_t;
    using std::uint64_t;
    using std::int8_t;
    using std::int16_t;
    using std::int32_t;
    using std::int64_t;
#endif

#ifdef __cplusplus
}
#endif

#endif // NVS_COMPAT_H
