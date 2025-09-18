#pragma once

#include "esp_err.h"
#include "driver/i2c.h"

// I2C определения
#define I2C_MASTER_NUM              I2C_NUM_0
#define BME280_ADDR                 0x76

esp_err_t bme280_init(void);
esp_err_t bme280_read(float *temperature, float *humidity, float *pressure); 