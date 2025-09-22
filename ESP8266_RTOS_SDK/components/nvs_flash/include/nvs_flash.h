#ifndef NVS_FLASH_H
#define NVS_FLASH_H

#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

// NVS types and constants
typedef uint32_t nvs_handle_t;
typedef uint8_t nvs_open_mode_t;

#define NVS_READONLY  0x01
#define NVS_READWRITE 0x02

// NVS error codes
#define ESP_ERR_NVS_NOT_INITIALIZED    0x1100
#define ESP_ERR_NVS_NOT_FOUND          0x1101
#define ESP_ERR_NVS_INVALID_NAME       0x1102
#define ESP_ERR_NVS_INVALID_HANDLE     0x1103
#define ESP_ERR_NVS_READ_ONLY          0x1104
#define ESP_ERR_NVS_NOT_ENOUGH_SPACE   0x1105
#define ESP_ERR_NVS_INVALID_LENGTH     0x1106
#define ESP_ERR_NVS_NO_FREE_PAGES      0x1107
#define ESP_ERR_NVS_VALUE_TOO_LONG     0x1108
#define ESP_ERR_NVS_PART_NOT_FOUND     0x1109
#define ESP_ERR_NVS_NEW_VERSION_FOUND  0x110A
#define ESP_ERR_NVS_XTS_ENCR_FAILED    0x110B
#define ESP_ERR_NVS_XTS_DECR_FAILED    0x110C
#define ESP_ERR_NVS_XTS_CFG_FAILED     0x110D
#define ESP_ERR_NVS_XTS_CFG_NOT_FOUND  0x110E
#define ESP_ERR_NVS_ENCR_NOT_SUPPORTED 0x110F
#define ESP_ERR_NVS_KEYS_NOT_INITIALIZED 0x1110
#define ESP_ERR_NVS_CORRUPT_KEY_PART   0x1111
#define ESP_ERR_NVS_CONTENT_DIFFERS    0x1112
#define ESP_ERR_NVS_WRONG_ENCRYPTION   0x1113

// Dummy NVS Flash functions for compatibility
esp_err_t nvs_flash_init(void);
esp_err_t nvs_flash_deinit(void);
esp_err_t nvs_flash_erase(void);
esp_err_t nvs_open(const char* name, nvs_open_mode_t open_mode, nvs_handle_t *out_handle);
void nvs_close(nvs_handle_t handle);
esp_err_t nvs_get_blob(nvs_handle_t handle, const char* key, void* out_value, size_t* length);
esp_err_t nvs_set_blob(nvs_handle_t handle, const char* key, const void* value, size_t length);
esp_err_t nvs_get_u32(nvs_handle_t handle, const char* key, uint32_t* out_value);
esp_err_t nvs_set_u32(nvs_handle_t handle, const char* key, uint32_t value);
esp_err_t nvs_erase_key(nvs_handle_t handle, const char* key);
esp_err_t nvs_commit(nvs_handle_t handle);

#ifdef __cplusplus
}
#endif

#endif // NVS_FLASH_H
