/*
 * NVS types header with compatibility fixes
 * Fixed for ESP8266 RTOS SDK v3.4
 */

#pragma once

// Compatibility fix for cstdint
#ifdef __cplusplus
extern "C" {
#endif

// Include stdint.h instead of cstdint for C++ compatibility
#include <stdint.h>

// If cstdint is not available, define necessary types
#ifndef __cplusplus
    // For C code, stdint.h should be sufficient
#else
    // For C++ code, ensure we have the necessary types
    #ifndef INT8_MAX
        #define INT8_MAX 127
    #endif
    #ifndef INT16_MAX
        #define INT16_MAX 32767
    #endif
    #ifndef INT32_MAX
        #define INT32_MAX 2147483647
    #endif
    #ifndef UINT8_MAX
        #define UINT8_MAX 255
    #endif
    #ifndef UINT16_MAX
        #define UINT16_MAX 65535
    #endif
    #ifndef UINT32_MAX
        #define UINT32_MAX 4294967295U
    #endif
#endif

// Original content from nvs_types.hpp
typedef uint8_t nvs_handle_t;

typedef enum {
    NVS_READONLY  = 0x01, // Read only
    NVS_READWRITE = 0x02  // Read and write
} nvs_open_mode_t;

typedef enum {
    NVS_TYPE_U8    = 0x01, // Type uint8_t
    NVS_TYPE_I8    = 0x11, // Type int8_t
    NVS_TYPE_U16   = 0x02, // Type uint16_t
    NVS_TYPE_I16   = 0x12, // Type int16_t
    NVS_TYPE_U32   = 0x04, // Type uint32_t
    NVS_TYPE_I32   = 0x14, // Type int32_t
    NVS_TYPE_U64   = 0x08, // Type uint64_t
    NVS_TYPE_I64   = 0x18, // Type int64_t
    NVS_TYPE_STR   = 0x21, // Type string
    NVS_TYPE_BLOB  = 0x42, // Type blob
    NVS_TYPE_ANY   = 0xff  // Must be last
} nvs_type_t;

#ifdef __cplusplus
}
#endif
