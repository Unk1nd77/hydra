#include "nvs_flash.h"
#include "esp_err.h"

// Dummy implementations of NVS functions
esp_err_t nvs_flash_init(void)
{
    return ESP_OK;
}

esp_err_t nvs_flash_deinit(void)
{
    return ESP_OK;
}

esp_err_t nvs_flash_erase(void)
{
    return ESP_OK;
}

esp_err_t nvs_open(const char* name, nvs_open_mode_t open_mode, nvs_handle_t *out_handle)
{
    if (out_handle) {
        *out_handle = 1; // Dummy handle
    }
    return ESP_OK;
}

void nvs_close(nvs_handle_t handle)
{
    // Do nothing
}

esp_err_t nvs_get_blob(nvs_handle_t handle, const char* key, void* out_value, size_t* length)
{
    if (length) {
        *length = 0;
    }
    return ESP_ERR_NVS_NOT_FOUND;
}

esp_err_t nvs_set_blob(nvs_handle_t handle, const char* key, const void* value, size_t length)
{
    return ESP_OK;
}

esp_err_t nvs_get_u32(nvs_handle_t handle, const char* key, uint32_t* out_value)
{
    if (out_value) {
        *out_value = 0;
    }
    return ESP_ERR_NVS_NOT_FOUND;
}

esp_err_t nvs_set_u32(nvs_handle_t handle, const char* key, uint32_t value)
{
    return ESP_OK;
}

esp_err_t nvs_erase_key(nvs_handle_t handle, const char* key)
{
    return ESP_OK;
}

esp_err_t nvs_commit(nvs_handle_t handle)
{
    return ESP_OK;
}

// Additional NVS functions used by the system
esp_err_t nvs_get_i8(nvs_handle_t handle, const char* key, int8_t* out_value)
{
    if (out_value) {
        *out_value = 0;
    }
    return ESP_ERR_NVS_NOT_FOUND;
}

esp_err_t nvs_set_i8(nvs_handle_t handle, const char* key, int8_t value)
{
    return ESP_OK;
}

esp_err_t nvs_get_u8(nvs_handle_t handle, const char* key, uint8_t* out_value)
{
    if (out_value) {
        *out_value = 0;
    }
    return ESP_ERR_NVS_NOT_FOUND;
}

esp_err_t nvs_set_u8(nvs_handle_t handle, const char* key, uint8_t value)
{
    return ESP_OK;
}

esp_err_t nvs_get_u16(nvs_handle_t handle, const char* key, uint16_t* out_value)
{
    if (out_value) {
        *out_value = 0;
    }
    return ESP_ERR_NVS_NOT_FOUND;
}

esp_err_t nvs_set_u16(nvs_handle_t handle, const char* key, uint16_t value)
{
    return ESP_OK;
}

