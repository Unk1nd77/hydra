#ifndef __ESP_FILE__
#define __ESP_FILE__ __FILE__
#endif
#include <stdio.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "freertos/portmacro.h"
#include "esp_system.h"
#include "esp_wifi.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "esp_http_server.h"
#include "driver/i2c.h"
#include "driver/gpio.h"
#include "bme280.h"
#include "lcd.h"
#include "tcpip_adapter.h"
#include "esp_spiffs.h"
#include "esp_http_client.h"
#include "cJSON.h"
#include "esp_ota_ops.h"
#include "sdkconfig.h"
#include <sys/param.h>

#ifndef CONFIG_ESP8266_WIFI_RX_BUFFER_NUM
#define CONFIG_ESP8266_WIFI_RX_BUFFER_NUM 10
#endif

// Определения для I2C (WeMos D1 Mini)
#define I2C_MASTER_SCL_IO           2                /*!< gpio number for I2C master clock */
#define I2C_MASTER_SDA_IO           14               /*!< gpio number for I2C master data  */
#define I2C_MASTER_NUM              I2C_NUM_0        /*!< I2C port number for master dev */
#define I2C_MASTER_TX_BUF_DISABLE   0                /*!< I2C master do not need buffer */
#define I2C_MASTER_RX_BUF_DISABLE   0                /*!< I2C master do not need buffer */
#define I2C_MASTER_FREQ_HZ          100000 // 100KHz для стабильной работы
#define I2C_MASTER_TIMEOUT_MS       1000

// Определения для WiFi
#define WIFI_SSID      "your_ssid"
#define WIFI_PASS      "your_password"
#define MAXIMUM_RETRY  5
#define AP_SSID        "Hydra-L"
#define AP_PASS        "12345678"
#define AP_MAX_CONN    4

// Определения для OTA
#define OTA_URL        "http://188.35.161.31/firmware/hydra-l.bin"
#define OTA_TIMEOUT_MS 30000

// Определения для FreeRTOS
// CONFIG_FREERTOS_HZ определен в sdkconfig.h

// Определения для кнопок
#define BUTTON_1_GPIO     12  // GPIO для кнопки 1
#define BUTTON_2_GPIO     13  // GPIO для кнопки 2
#define DEBOUNCE_TIME_MS  50  // Время debounce в миллисекундах

// Глобальные переменные
static const char *TAG = "ESP8266_RTOS";
static EventGroupHandle_t s_wifi_event_group;
#define WIFI_CONNECTED_BIT BIT0
#define WIFI_FAIL_BIT      BIT1

static int s_retry_num = 0;
// static httpd_handle_t server = NULL;  // Удалено - не используется

// Структуры для хранения данных
typedef struct {
    float temperature;
    float humidity;
    float pressure;
} sensor_data_t;

static sensor_data_t sensor_data = {0};

// Добавляем глобальные переменные
static char lcd_string1[17] = {0};  // 16 символов + нулевой
static char lcd_string2[17] = {0};
static char lcd_mode = '0';         // '0' - показания, '1' - пейджер, '2' - IP
static bool lcd_backlight = true;
static char device_name[32] = {0};
static char akey[32] = {0};

// Глобальные переменные для сетевой информации
static char current_ip[16] = "0.0.0.0";
static char current_mac[18] = "00:00:00:00:00:00";
static int current_rssi = 0;

// Структура для усреднения показаний
#define SENSOR_AVG_COUNT 5
typedef struct {
    float values[SENSOR_AVG_COUNT];
    int index;
    int count;
} sensor_avg_t;

static sensor_avg_t temp_avg = {0};
static sensor_avg_t hum_avg = {0};
static sensor_avg_t press_avg = {0};

// Структура для хранения состояния кнопок
typedef struct {
    uint32_t last_press_time;
    bool is_pressed;
} button_state_t;

static button_state_t button1_state = {0};
static button_state_t button2_state = {0};

// Функция для обновления скользящего среднего
static float update_average(sensor_avg_t *avg, float new_value) {
    avg->values[avg->index] = new_value;
    avg->index = (avg->index + 1) % SENSOR_AVG_COUNT;
    if (avg->count < SENSOR_AVG_COUNT) avg->count++;
    
    float sum = 0;
    for (int i = 0; i < avg->count; i++) {
        sum += avg->values[i];
    }
    return sum / avg->count;
}

// Инициализация I2C
static esp_err_t i2c_master_init()
{
    int i2c_master_port = I2C_MASTER_NUM;
    i2c_config_t conf;
    conf.mode = I2C_MODE_MASTER;
    conf.sda_io_num = I2C_MASTER_SDA_IO;
    conf.sda_pullup_en = 1;
    conf.scl_io_num = I2C_MASTER_SCL_IO;
    conf.scl_pullup_en = 1;
    conf.clk_stretch_tick = 300; // 300 ticks, Clock stretch is about 210us
    esp_err_t err;
    err = i2c_driver_install(i2c_master_port, conf.mode);
    if (err != ESP_OK) {
        printf("I2C driver install failed: %d\n", err);
        return err;
    }
    err = i2c_param_config(i2c_master_port, &conf);
    if (err != ESP_OK) {
        printf("I2C param config failed: %d\n", err);
        return err;
    }
    return ESP_OK;
}

// Прототипы функций
static void event_handler(void* arg, esp_event_base_t event_base,
                                int32_t event_id, void* event_data);
static void wifi_init_sta(void);
static esp_err_t root_handler(httpd_req_t *req);
static esp_err_t data_handler(httpd_req_t *req);
static void sensor_task(void *pvParameters);
static void lcd_task(void *pvParameters);
static void server_task(void *pvParameters);
static void button_task(void *pvParameters);
static void get_mac_address(void);
static void get_ip_address(void);
static void get_rssi(void);

// Обработчик событий WiFi
static void event_handler(void* arg, esp_event_base_t event_base,
                                int32_t event_id, void* event_data)
{
    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        if (s_retry_num < MAXIMUM_RETRY) {
            esp_wifi_connect();
            s_retry_num++;
            ESP_LOGI(TAG, "retry to connect to the AP");
        } else {
            xEventGroupSetBits(s_wifi_event_group, WIFI_FAIL_BIT);
        }
        ESP_LOGI(TAG,"connect to the AP fail");
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        ip_event_got_ip_t* event = (ip_event_got_ip_t*) event_data;
        ESP_LOGI(TAG, "got ip:" IPSTR, IP2STR(&event->ip_info.ip));
        s_retry_num = 0;
        xEventGroupSetBits(s_wifi_event_group, WIFI_CONNECTED_BIT);
        get_mac_address();
        get_ip_address();
        get_rssi();
    }
}

// Функция для получения MAC-адреса
static void get_mac_address(void)
{
    uint8_t mac[6];
    esp_wifi_get_mac(WIFI_IF_STA, mac);
    snprintf(current_mac, sizeof(current_mac), "%02x:%02x:%02x:%02x:%02x:%02x",
             mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
}

// Обновляем функцию получения IP-адреса
static void get_ip_address(void)
{
    tcpip_adapter_ip_info_t ip_info;
    if (tcpip_adapter_get_ip_info(TCPIP_ADAPTER_IF_STA, &ip_info) == ESP_OK) {
        snprintf(current_ip, sizeof(current_ip), IPSTR, IP2STR(&ip_info.ip));
    }
}

// Функция для получения RSSI
static void get_rssi(void)
{
    wifi_ap_record_t ap_info;
    if (esp_wifi_sta_get_ap_info(&ap_info) == ESP_OK) {
        current_rssi = ap_info.rssi;
    }
}

// Обработчик корневого URL
static esp_err_t root_handler(httpd_req_t *req)
{
    const char resp[] = "ESP8266 RTOS Web Server";
    httpd_resp_send(req, resp, strlen(resp));
    return ESP_OK;
}

// Обработчик для получения данных
static esp_err_t data_handler(httpd_req_t *req)
{
    char buf[256];
    snprintf(buf, sizeof(buf),
             "{\"temperature\":%.1f,\"humidity\":%.1f,\"pressure\":%.1f,\"rssi\":%d,\"mac\":\"%s\",\"ip\":\"%s\"}",
             sensor_data.temperature, sensor_data.humidity, sensor_data.pressure,
             current_rssi, current_mac, current_ip);
    
    httpd_resp_set_type(req, "application/json");
    httpd_resp_send(req, buf, strlen(buf));
    return ESP_OK;
}

// Обновляем функцию send_data_to_server для использования реальных данных
static void send_data_to_server(void)
{
    cJSON *root = cJSON_CreateObject();
    cJSON *system = cJSON_CreateObject();
    cJSON *bme280 = cJSON_CreateObject();
    
    cJSON_AddStringToObject(system, "Akey", akey);
    cJSON_AddStringToObject(system, "Serial", device_name);
    cJSON_AddStringToObject(system, "Version", "2024-03-20");
    cJSON_AddNumberToObject(system, "RSSI", current_rssi);
    cJSON_AddStringToObject(system, "MAC", current_mac);
    cJSON_AddStringToObject(system, "IP", current_ip);
    
    cJSON_AddNumberToObject(bme280, "temp", sensor_data.temperature);
    cJSON_AddNumberToObject(bme280, "humidity", sensor_data.humidity);
    cJSON_AddNumberToObject(bme280, "pressure", sensor_data.pressure);
    
    cJSON_AddItemToObject(root, "system", system);
    cJSON_AddItemToObject(root, "BME280", bme280);
    
    char *json_str = cJSON_Print(root);
    cJSON_Delete(root);
    
    esp_http_client_config_t config = {
        .url = "http://188.35.161.31/core/jsonadd.php",
        .method = HTTP_METHOD_POST,
    };
    
    esp_http_client_handle_t client = esp_http_client_init(&config);
    esp_http_client_set_post_field(client, json_str, strlen(json_str));
    esp_http_client_set_header(client, "Content-Type", "application/json");
    
    esp_http_client_perform(client);
    esp_http_client_cleanup(client);
    free(json_str);
}

// Добавляем функцию load_config
static esp_err_t load_config(void)
{
    FILE *f = fopen("/spiffs/config.txt", "r");
    if (f == NULL) {
        ESP_LOGE(TAG, "Failed to open config.txt");
        return ESP_FAIL;
    }
    
    char line[64];
    if (fgets(line, sizeof(line), f)) {
        line[strcspn(line, "\n")] = 0;
        strncpy(device_name, line, sizeof(device_name) - 1);
    }
    if (fgets(line, sizeof(line), f)) {
        line[strcspn(line, "\n")] = 0;
        strncpy(akey, line, sizeof(akey) - 1);
    }
    if (fgets(line, sizeof(line), f)) {
        line[strcspn(line, "\n")] = 0;
        strncpy(WIFI_SSID, line, sizeof(WIFI_SSID) - 1);
    }
    if (fgets(line, sizeof(line), f)) {
        line[strcspn(line, "\n")] = 0;
        strncpy(WIFI_PASS, line, sizeof(WIFI_PASS) - 1);
    }
    
    fclose(f);
    return ESP_OK;
}

// Обработчик для установки режима LCD
static esp_err_t set_mode_handler(httpd_req_t *req)
{
    char buf[10];
    int ret = httpd_req_recv(req, buf, sizeof(buf) - 1);
    if (ret <= 0) {
        return ESP_FAIL;
    }
    buf[ret] = '\0';
    
    lcd_mode = buf[0];
    lcd_clear();
    
    char lcd_buf[32];
    switch(lcd_mode) {
        case '0':
            lcd_set_cursor(0, 0);
            snprintf(lcd_buf, sizeof(lcd_buf), "T=%.1fC H=%.1f%%", sensor_data.temperature, sensor_data.humidity);
            lcd_print(lcd_buf);
            lcd_set_cursor(0, 1);
            snprintf(lcd_buf, sizeof(lcd_buf), "P=%.1fmmHg", sensor_data.pressure);
            lcd_print(lcd_buf);
            break;
        case '1':
            lcd_set_cursor(0, 0);
            lcd_print(lcd_string1);
            lcd_set_cursor(0, 1);
            lcd_print(lcd_string2);
            break;
        case '2':
            lcd_set_cursor(0, 0);
            lcd_print("Local IP");
            lcd_set_cursor(0, 1);
            lcd_print(current_ip);
            break;
    }
    
    httpd_resp_send(req, "OK", 2);
    return ESP_OK;
}

// Обработчик для установки текста LCD
static esp_err_t set_lcd_handler(httpd_req_t *req)
{
    char buf[100];
    int ret = httpd_req_recv(req, buf, sizeof(buf) - 1);
    if (ret <= 0) {
        return ESP_FAIL;
    }
    buf[ret] = '\0';
    
    char *num = strtok(buf, "=");
    char *str = strtok(NULL, "=");
    
    if (num && str) {
        if (strcmp(num, "1") == 0) {
            strncpy(lcd_string1, str, 16);
            lcd_string1[16] = '\0';
        } else if (strcmp(num, "2") == 0) {
            strncpy(lcd_string2, str, 16);
            lcd_string2[16] = '\0';
        }
    }
    
    httpd_resp_send(req, "OK", 2);
    return ESP_OK;
}

// Обработчик для управления подсветкой
static esp_err_t set_led_handler(httpd_req_t *req)
{
    char buf[10];
    int ret = httpd_req_recv(req, buf, sizeof(buf) - 1);
    if (ret <= 0) {
        return ESP_FAIL;
    }
    buf[ret] = '\0';
    
    if (strcmp(buf, "1") == 0) {
        lcd_backlight = true;
        lcd_backlight_on();
    } else {
        lcd_backlight = false;
        lcd_backlight_off();
    }
    
    httpd_resp_send(req, "OK", 2);
    return ESP_OK;
}

// Инициализация SPIFFS - функция удалена, так как не используется

// Обработчик для отдачи HTML файлов
static esp_err_t html_handler(httpd_req_t *req)
{
    char filepath[256];  // Увеличиваем размер буфера
    const char *uri = req->uri;
    
    // Если запрос корневой страницы, отдаем index.html
    if (strcmp(uri, "/") == 0) {
        strcpy(filepath, "/spiffs/index.html");
    } else {
        // Проверяем длину URI
        if (strlen(uri) > 200) {
            httpd_resp_send_404(req);
            return ESP_FAIL;
        }
        // Иначе отдаем запрошенный файл
        #pragma GCC diagnostic push
        #pragma GCC diagnostic ignored "-Wformat-truncation"
        snprintf(filepath, sizeof(filepath), "/spiffs%s", uri);
        #pragma GCC diagnostic pop
    }
    
    // Проверяем существование файла
    FILE *f = fopen(filepath, "r");
    if (f == NULL) {
        httpd_resp_send_404(req);
        return ESP_FAIL;
    }
    
    // Определяем тип контента по расширению
    const char *ext = strrchr(filepath, '.');
    if (ext != NULL) {
        if (strcmp(ext, ".html") == 0) {
            httpd_resp_set_type(req, "text/html");
        } else if (strcmp(ext, ".css") == 0) {
            httpd_resp_set_type(req, "text/css");
        } else if (strcmp(ext, ".js") == 0) {
            httpd_resp_set_type(req, "application/javascript");
        }
    }
    
    // Отправляем файл
    char buf[1024];
    size_t read;
    while ((read = fread(buf, 1, sizeof(buf), f)) > 0) {
        httpd_resp_send_chunk(req, buf, read);
    }
    
    fclose(f);
    httpd_resp_send_chunk(req, NULL, 0);
    return ESP_OK;
}

// Определения URI handlers
static const httpd_uri_t root = {
    .uri       = "/",
    .method    = HTTP_GET,
    .handler   = root_handler,
    .user_ctx  = NULL
};

static const httpd_uri_t data = {
    .uri       = "/getData",
    .method    = HTTP_GET,
    .handler   = data_handler,
    .user_ctx  = NULL
};

static const httpd_uri_t set_mode = {
    .uri       = "/setMode",
    .method    = HTTP_POST,
    .handler   = set_mode_handler,
    .user_ctx  = NULL
};

static const httpd_uri_t set_lcd = {
    .uri       = "/setLCD",
    .method    = HTTP_POST,
    .handler   = set_lcd_handler,
    .user_ctx  = NULL
};

static const httpd_uri_t set_led = {
    .uri       = "/setLED",
    .method    = HTTP_POST,
    .handler   = set_led_handler,
    .user_ctx  = NULL
};

// Обновляем функцию start_webserver для добавления обработчика HTML
static httpd_handle_t start_webserver(void)
{
    httpd_handle_t server = NULL;
    httpd_config_t config = HTTPD_DEFAULT_CONFIG();

    if (httpd_start(&server, &config) == ESP_OK) {
        httpd_uri_t html = {
            .uri       = "/*",
            .method    = HTTP_GET,
            .handler   = html_handler,
            .user_ctx  = NULL
        };
        httpd_register_uri_handler(server, &html);
        
        httpd_register_uri_handler(server, &root);
        httpd_register_uri_handler(server, &data);
        httpd_register_uri_handler(server, &set_mode);
        httpd_register_uri_handler(server, &set_lcd);
        httpd_register_uri_handler(server, &set_led);
        return server;
    }

    ESP_LOGI(TAG, "Error starting server!");
    return NULL;
}

// Функция stop_webserver удалена - не используется

// Обработчики событий WiFi удалены - не используются

// Задача веб-сервера удалена - не используется

/* An HTTP GET handler */
esp_err_t hello_get_handler(httpd_req_t *req)
{
    char*  buf;
    size_t buf_len;

    /* Get header value string length and allocate memory for length + 1,
     * extra byte for null termination */
    buf_len = httpd_req_get_hdr_value_len(req, "Host") + 1;
    if (buf_len > 1) {
        buf = malloc(buf_len);
        /* Copy null terminated value string into buffer */
        if (httpd_req_get_hdr_value_str(req, "Host", buf, buf_len) == ESP_OK) {
            ESP_LOGI(TAG, "Found header => Host: %s", buf);
        }
        free(buf);
    }

    /* Send response */
    const char* resp_str = "Hello World!";
    httpd_resp_send(req, resp_str, strlen(resp_str));
    return ESP_OK;
}

/* An HTTP POST handler */
esp_err_t echo_post_handler(httpd_req_t *req)
{
    char buf[100];
    int ret, remaining = req->content_len;

    while (remaining > 0) {
        /* Read the data for the request */
        if ((ret = httpd_req_recv(req, buf,
                        MIN(remaining, sizeof(buf)))) <= 0) {
            if (ret == HTTPD_SOCK_ERR_TIMEOUT) {
                /* Retry receiving if timeout occurred */
                continue;
            }
            return ESP_FAIL;
        }

        /* Send back the same data */
        httpd_resp_send_chunk(req, buf, ret);
        remaining -= ret;

        /* Log data received */
        ESP_LOGI(TAG, "=========== RECEIVED DATA ==========");
        ESP_LOGI(TAG, "%.*s", ret, buf);
        ESP_LOGI(TAG, "====================================");
    }

    // End response
    httpd_resp_send_chunk(req, NULL, 0);
    return ESP_OK;
}

httpd_uri_t hello = {
    .uri       = "/hello",
    .method    = HTTP_GET,
    .handler   = hello_get_handler,
    .user_ctx  = NULL
};

httpd_uri_t echo = {
    .uri       = "/echo",
    .method    = HTTP_POST,
    .handler   = echo_post_handler,
    .user_ctx  = NULL
};

// Обновляем sensor_task для использования усреднения
static void sensor_task(void *pvParameters)
{
    while (1) {
        float temp, hum, press;
        if (bme280_read(&temp, &hum, &press) == ESP_OK) {
            sensor_data.temperature = update_average(&temp_avg, temp);
            sensor_data.humidity = update_average(&hum_avg, hum);
            sensor_data.pressure = update_average(&press_avg, press);
            
            // Отправляем данные каждые 60 секунд
            static int counter = 0;
            if (++counter >= 12) { // 12 * 5 секунд = 60 секунд
                send_data_to_server();
                counter = 0;
            }
        }
        vTaskDelay(pdMS_TO_TICKS(5000));
    }
}

// Обновляем lcd_task для поддержки разных режимов
static void lcd_task(void *pvParameters)
{
    char buf[32];
    while (1) {
        switch(lcd_mode) {
            case '0':
                lcd_clear();
                lcd_set_cursor(0, 0);
                snprintf(buf, sizeof(buf), "T=%.1fC H=%.1f%%", sensor_data.temperature, sensor_data.humidity);
                lcd_print(buf);
                lcd_set_cursor(0, 1);
                snprintf(buf, sizeof(buf), "P=%.1fmmHg", sensor_data.pressure);
                lcd_print(buf);
                break;
            case '1':
                lcd_clear();
                lcd_set_cursor(0, 0);
                lcd_print(lcd_string1);
                lcd_set_cursor(0, 1);
                lcd_print(lcd_string2);
                break;
            case '2':
                lcd_clear();
                lcd_set_cursor(0, 0);
                lcd_print("Local IP");
                lcd_set_cursor(0, 1);
                lcd_print(current_ip);
                break;
        }
        vTaskDelay(pdMS_TO_TICKS(2000));
    }
}

// Обновляем функцию perform_ota_update для использования HTTP вместо HTTPS
static esp_err_t perform_ota_update(void)
{
    esp_http_client_config_t config = {
        .url = OTA_URL,
        .timeout_ms = OTA_TIMEOUT_MS,
    };

    esp_ota_handle_t ota_handle;
    const esp_partition_t *update_partition = esp_ota_get_next_update_partition(NULL);
    
    if (update_partition == NULL) {
        ESP_LOGE(TAG, "No update partition found!");
        return ESP_FAIL;
    }

    esp_err_t err = esp_ota_begin(update_partition, OTA_SIZE_UNKNOWN, &ota_handle);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "esp_ota_begin failed (%s)", esp_err_to_name(err));
        return err;
    }

    esp_http_client_handle_t client = esp_http_client_init(&config);
    esp_http_client_perform(client);

    int content_length = esp_http_client_get_content_length(client);
    int total_read = 0;
    char *buffer = malloc(1024);
    
    while (total_read < content_length) {
        int read = esp_http_client_read(client, buffer, 1024);
        if (read <= 0) break;
        
        err = esp_ota_write(ota_handle, buffer, read);
        if (err != ESP_OK) {
            ESP_LOGE(TAG, "esp_ota_write failed (%s)", esp_err_to_name(err));
            break;
        }
        total_read += read;
    }
    
    free(buffer);
    esp_http_client_cleanup(client);

    if (err == ESP_OK) {
        err = esp_ota_end(ota_handle);
        if (err == ESP_OK) {
            err = esp_ota_set_boot_partition(update_partition);
            if (err == ESP_OK) {
                ESP_LOGI(TAG, "OTA update successful, restarting...");
                esp_restart();
            }
        }
    }

    ESP_LOGE(TAG, "OTA update failed!");
    return err;
}

// Задача для отправки данных на сервер
static void server_task(void *pvParameters)
{
    while (1) {
        send_data_to_server();
        vTaskDelay(pdMS_TO_TICKS(60000)); // Отправка каждую минуту
    }
}

// Функция инициализации WiFi в режиме AP
static void wifi_init_softap(void)
{
    wifi_config_t wifi_config = {
        .ap = {
            .ssid = AP_SSID,
            .ssid_len = strlen(AP_SSID),
            .password = AP_PASS,
            .max_connection = AP_MAX_CONN,
            .authmode = WIFI_AUTH_WPA_WPA2_PSK
        },
    };

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_APSTA));
    ESP_ERROR_CHECK(esp_wifi_set_config(ESP_IF_WIFI_AP, &wifi_config));
    ESP_ERROR_CHECK(esp_wifi_start());

    ESP_LOGI(TAG, "wifi_init_softap finished. SSID:%s password:%s",
             wifi_config.ap.ssid, wifi_config.ap.password);
}

// Функция инициализации WiFi в режиме STA
static void wifi_init_sta(void)
{
    s_wifi_event_group = xEventGroupCreate();

    tcpip_adapter_init();
    ESP_ERROR_CHECK(esp_event_loop_create_default());
    // tcpip_adapter_create_default_wifi_sta(); // Удалено для ESP8266

    wifi_init_config_t cfg = {0};
    esp_wifi_init(&cfg);

    ESP_ERROR_CHECK(esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &event_handler, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_STA_GOT_IP, &event_handler, NULL));

    wifi_config_t wifi_config = {
        .sta = {
            .ssid = WIFI_SSID,
            .password = WIFI_PASS
        },
    };

    if (strlen((char *)wifi_config.sta.password)) {
        wifi_config.sta.threshold.authmode = WIFI_AUTH_WPA2_PSK;
    }

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_APSTA));
    ESP_ERROR_CHECK(esp_wifi_set_config(ESP_IF_WIFI_STA, &wifi_config));
    ESP_ERROR_CHECK(esp_wifi_start());

    ESP_LOGI(TAG, "wifi_init_sta finished.");

    EventBits_t bits = xEventGroupWaitBits(s_wifi_event_group,
            WIFI_CONNECTED_BIT | WIFI_FAIL_BIT,
            pdFALSE,
            pdFALSE,
            portMAX_DELAY);

    if (bits & WIFI_CONNECTED_BIT) {
        ESP_LOGI(TAG, "connected to ap SSID:%s password:%s",
                 wifi_config.sta.ssid, wifi_config.sta.password);
        get_mac_address();
        get_ip_address();
        get_rssi();
    } else if (bits & WIFI_FAIL_BIT) {
        ESP_LOGI(TAG, "Failed to connect to SSID:%s, password:%s",
                 wifi_config.sta.ssid, wifi_config.sta.password);
    } else {
        ESP_LOGE(TAG, "UNEXPECTED EVENT");
    }
}

// Обработчик прерывания для кнопок
static void IRAM_ATTR button_isr_handler(void* arg)
{
    button_state_t* button = (button_state_t*) arg;
    uint32_t current_time = xTaskGetTickCount() * portTICK_PERIOD_MS;
    
    if (current_time - button->last_press_time > DEBOUNCE_TIME_MS) {
        button->is_pressed = true;
        button->last_press_time = current_time;
    }
}

// Задача для обработки нажатий кнопок
static void button_task(void *pvParameters)
{
    // Настройка GPIO для кнопок
    gpio_config_t io_conf = {
        .pin_bit_mask = (1ULL << BUTTON_1_GPIO) | (1ULL << BUTTON_2_GPIO),
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_ENABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_NEGEDGE
    };
    gpio_config(&io_conf);
    
    // Установка обработчиков прерываний
    gpio_install_isr_service(0);
    gpio_isr_handler_add(BUTTON_1_GPIO, button_isr_handler, &button1_state);
    gpio_isr_handler_add(BUTTON_2_GPIO, button_isr_handler, &button2_state);
    
    while (1) {
        if (button1_state.is_pressed) {
            // Обработка нажатия кнопки 1
            lcd_mode = (lcd_mode + 1) % 3;  // Переключение режимов
            button1_state.is_pressed = false;
        }
        
        if (button2_state.is_pressed) {
            // Обработка нажатия кнопки 2
            lcd_backlight = !lcd_backlight;  // Переключение подсветки
            if (lcd_backlight) {
                lcd_backlight_on();
            } else {
                lcd_backlight_off();
            }
            button2_state.is_pressed = false;
        }
        
        vTaskDelay(pdMS_TO_TICKS(10));  // Небольшая задержка для снижения нагрузки
    }
}

void app_main(void)
{
    // 
    
    
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NOT_FOUND) {
        ESP_LOGI(TAG, "NVS partition was truncated and needs to be erased");
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "NVS init failed: %s", esp_err_to_name(ret));
        return;
    }
    ESP_LOGI(TAG, "NVS initialized successfully");

    // Инициализация I2C
    i2c_master_init();

    // Инициализация LCD
    lcd_init();
    lcd_clear();
    lcd_set_cursor(0, 0);
    lcd_print("Hydra-L");
    lcd_set_cursor(0, 1);
    lcd_print("Starting...");

    // Инициализация BME280
    bme280_init();

    // Инициализация WiFi
    wifi_init_sta();
    wifi_init_softap();

    // Инициализация SPIFFS
    esp_vfs_spiffs_conf_t conf = {
        .base_path = "/spiffs",
        .partition_label = NULL,
        .max_files = 5,
        .format_if_mount_failed = true
    };
    ESP_ERROR_CHECK(esp_vfs_spiffs_register(&conf));

    // Загрузка конфигурации
    load_config();

    // Создание задач
    xTaskCreate(sensor_task, "sensor_task", 4096, NULL, 5, NULL);
    xTaskCreate(lcd_task, "lcd_task", 4096, NULL, 5, NULL);
    xTaskCreate(server_task, "server_task", 4096, NULL, 5, NULL);
    xTaskCreate(button_task, "button_task", 2048, NULL, 5, NULL);  // Добавляем задачу обработки кнопок

    // Запуск веб-сервера
    start_webserver();

    // Проверка обновлений
    perform_ota_update();
} 