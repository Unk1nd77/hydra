#pragma once

#include "esp_err.h"
#include "driver/i2c.h"

// I2C определения
#define I2C_MASTER_NUM              I2C_NUM_0

esp_err_t lcd_init(void);
esp_err_t lcd_clear(void);
esp_err_t lcd_set_cursor(uint8_t col, uint8_t row);
esp_err_t lcd_print(const char *str);
esp_err_t lcd_backlight_on(void);
esp_err_t lcd_backlight_off(void); 