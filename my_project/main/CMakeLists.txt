idf_component_register(
    SRCS "main.c"
    INCLUDE_DIRS "."
    REQUIRES nvs_flash esp8266 esp_http_server spiffs esp_http_client json app_update tcpip_adapter bme280 lcd
)
