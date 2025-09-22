#ifndef NVS_H
#define NVS_H

#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

// Dummy NVS functions for compatibility
esp_err_t nvs_flash_init(void);
esp_err_t nvs_flash_deinit(void);

#ifdef __cplusplus
}
#endif

#endif // NVS_H

