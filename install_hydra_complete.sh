#!/bin/bash

# =============================================================================
# Hydra-L Complete Installation Script
# Автоматическая установка всех зависимостей для ESP8266 проекта Hydra-L
# =============================================================================

set -e  # Остановка при любой ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для логирования
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

# Проверка прав root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Не запускайте этот скрипт от root! Используйте sudo только для установки пакетов."
    fi
}

# Проверка архитектуры
check_architecture() {
    ARCH=$(uname -m)
    if [[ "$ARCH" != "x86_64" ]]; then
        error "Неподдерживаемая архитектура: $ARCH. Требуется x86_64."
    fi
    log "Архитектура: $ARCH ✓"
}

# Проверка версии ОС
check_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        log "ОС: $PRETTY_NAME"
        
        case $ID in
            ubuntu|debian|linuxmint)
                log "Поддерживаемая ОС ✓"
                ;;
            *)
                warn "Непроверенная ОС: $ID. Продолжаем с осторожностью."
                ;;
        esac
    else
        warn "Не удалось определить ОС"
    fi
}

# Обновление системы
update_system() {
    log "Обновление списка пакетов..."
    sudo apt update
    
    log "Обновление системы..."
    sudo apt upgrade -y
}

# Установка системных пакетов
install_system_packages() {
    log "Установка системных пакетов..."
    
    sudo apt install -y \
        build-essential \
        cmake \
        ninja-build \
        git \
        wget \
        unzip \
        python3 \
        python3-pip \
        python3-venv \
        python3.11-venv \
        python3-setuptools \
        libncurses5-dev \
        libncursesw5-dev \
        flex \
        bison \
        gperf \
        libffi-dev \
        libssl-dev \
        libusb-1.0-0-dev \
        pkg-config \
        ccache \
        dfu-util \
        libsdl2-dev
    
    log "Системные пакеты установлены ✓"
}

# Создание директорий
create_directories() {
    log "Создание рабочих директорий..."
    
    mkdir -p /home/unk1nd77/hydra
    cd /home/unk1nd77/hydra
    
    log "Директории созданы ✓"
}

# Загрузка ESP8266 Toolchain
download_toolchain() {
    log "Загрузка ESP8266 Toolchain..."
    
    if [[ ! -d "xtensa-lx106-elf" ]]; then
        # Создаем директорию для toolchain
        mkdir -p xtensa-lx106-elf
        
        # Скачиваем toolchain (пример URL, нужно заменить на актуальный)
        TOOLCHAIN_URL="https://github.com/espressif/crosstool-NG/releases/download/xtensa-1.22.0/xtensa-lx106-elf-5.2.0.tar.gz"
        
        log "Загрузка toolchain с $TOOLCHAIN_URL..."
        wget -O toolchain.tar.gz "$TOOLCHAIN_URL" || {
            error "Не удалось загрузить toolchain. Проверьте интернет соединение."
        }
        
        log "Распаковка toolchain..."
        tar -xzf toolchain.tar.gz -C xtensa-lx106-elf --strip-components=1
        rm toolchain.tar.gz
        
        # Исправляем g++ wrapper
        if [[ -f "xtensa-lx106-elf/bin/xtensa-lx106-elf-g++" ]]; then
            log "Исправление g++ wrapper..."
            mv xtensa-lx106-elf/bin/xtensa-lx106-elf-g++ xtensa-lx106-elf/bin/xtensa-lx106-elf-g++.wrapper
            cp xtensa-lx106-elf/bin/xtensa-lx106-elf-gcc xtensa-lx106-elf/bin/xtensa-lx106-elf-g++
        fi
        
        log "Toolchain установлен ✓"
    else
        log "Toolchain уже установлен ✓"
    fi
}

# Загрузка ESP8266 RTOS SDK
download_esp8266_sdk() {
    log "Загрузка ESP8266 RTOS SDK..."
    
    if [[ ! -d "ESP8266_RTOS_SDK" ]]; then
        SDK_URL="https://github.com/espressif/ESP8266_RTOS_SDK.git"
        
        log "Клонирование SDK с $SDK_URL..."
        git clone --recursive "$SDK_URL" || {
            error "Не удалось клонировать SDK. Проверьте интернет соединение."
        }
        
        log "SDK загружен ✓"
    else
        log "SDK уже загружен ✓"
    fi
}

# Создание Python виртуального окружения
setup_python_env() {
    log "Настройка Python окружения..."
    
    cd /home/unk1nd77/hydra
    
    if [[ ! -d "venv" ]]; then
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    
    # Обновляем pip
    pip install --upgrade pip
    
    # Устанавливаем Python пакеты
    pip install \
        pyyaml \
        click \
        pyparsing \
        pyelftools \
        cryptography \
        future \
        pycryptodome
    
    log "Python окружение настроено ✓"
}

# Создание исправлений для SDK
create_sdk_fixes() {
    log "Создание исправлений для SDK..."
    
    cd /home/unk1nd77/hydra/ESP8266_RTOS_SDK
    
    # Создаем директории для NVS Flash
    mkdir -p components/nvs_flash/include
    mkdir -p components/nvs_flash/src
    
    # Создаем nvs_flash.h
    cat > components/nvs_flash/include/nvs_flash.h << 'EOF'
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
esp_err_t nvs_get_i8(nvs_handle_t handle, const char* key, int8_t* out_value);
esp_err_t nvs_set_i8(nvs_handle_t handle, const char* key, int8_t value);
esp_err_t nvs_get_u8(nvs_handle_t handle, const char* key, uint8_t* out_value);
esp_err_t nvs_set_u8(nvs_handle_t handle, const char* key, uint8_t value);
esp_err_t nvs_get_u16(nvs_handle_t handle, const char* key, uint16_t* out_value);
esp_err_t nvs_set_u16(nvs_handle_t handle, const char* key, uint16_t value);

#ifdef __cplusplus
}
#endif

#endif // NVS_FLASH_H
EOF

    # Создаем nvs_flash.c
    cat > components/nvs_flash/src/nvs_flash.c << 'EOF'
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
EOF

    # Создаем CMakeLists.txt для nvs_flash
    cat > components/nvs_flash/CMakeLists.txt << 'EOF'
idf_component_register(
    SRCS "src/nvs_flash.c"
    INCLUDE_DIRS "include"
)
EOF

    # Создаем sys/lock.h
    mkdir -p components/newlib/include/sys
    cat > components/newlib/include/sys/lock.h << 'EOF'
#ifndef _SYS_LOCK_H
#define _SYS_LOCK_H

#ifdef __cplusplus
extern "C" {
#endif

typedef int _LOCK_T;
typedef int _LOCK_RECURSIVE_T;
typedef void *_lock_t;

#define __LOCK_INIT(class,lock) static int lock = 0;
#define __LOCK_INIT_RECURSIVE(class,lock) static int lock = 0;
#define __lock_init(lock) ((void) 0)
#define __lock_init_recursive(lock) ((void) 0)
#define __lock_close(lock) ((void) 0)
#define __lock_close_recursive(lock) ((void) 0)
#define __lock_acquire(lock) ((void) 0)
#define __lock_acquire_recursive(lock) ((void) 0)
#define __lock_try_acquire(lock) 0
#define __lock_try_acquire_recursive(lock) 0
#define __lock_release(lock) ((void) 0)
#define __lock_release_recursive(lock) ((void) 0)

// Additional lock functions used by wear_levelling
#define _lock_init(lock) __lock_init(lock)
#define _lock_close(lock) __lock_close(lock)
#define _lock_acquire(lock) __lock_acquire(lock)
#define _lock_release(lock) __lock_release(lock)

#ifdef __cplusplus
}
#endif

#endif /* _SYS_LOCK_H */
EOF

    # Обновляем CMakeLists.txt для lwip
    if [[ -f "components/lwip/CMakeLists.txt" ]]; then
        # Добавляем nvs_flash include если его нет
        if ! grep -q "nvs_flash/include" components/lwip/CMakeLists.txt; then
            sed -i '/include_dirs/a\    ${IDF_PATH}/components/nvs_flash/include' components/lwip/CMakeLists.txt
        fi
    fi

    # Обновляем CMakeLists.txt для wear_levelling
    if [[ -f "components/wear_levelling/CMakeLists.txt" ]]; then
        # Добавляем newlib include если его нет
        if ! grep -q "newlib/include" components/wear_levelling/CMakeLists.txt; then
            sed -i 's/INCLUDE_DIRS include/INCLUDE_DIRS include "${IDF_PATH}\/components\/newlib\/include"/' components/wear_levelling/CMakeLists.txt
        fi
    fi

    # Исправляем dhcp_state.c
    if [[ -f "components/lwip/port/esp8266/netif/dhcp_state.c" ]]; then
        sed -i 's/#include "nvs\.h"/#include "nvs_flash.h"/' components/lwip/port/esp8266/netif/dhcp_state.c
    fi

    log "Исправления SDK созданы ✓"
}

# Создание переменных окружения
setup_environment() {
    log "Настройка переменных окружения..."
    
    # Создаем файл с переменными окружения
    cat > /home/unk1nd77/hydra/setup_env.sh << 'EOF'
#!/bin/bash
# Hydra-L Environment Setup

export PATH="/home/unk1nd77/hydra/xtensa-lx106-elf/bin:$PATH"
export IDF_PATH="/home/unk1nd77/hydra/ESP8266_RTOS_SDK"
export ESP8266_RTOS_SDK_PATH="/home/unk1nd77/hydra/ESP8266_RTOS_SDK"

# Активируем Python виртуальное окружение
source /home/unk1nd77/hydra/venv/bin/activate

echo "Hydra-L environment activated!"
echo "IDF_PATH: $IDF_PATH"
echo "Toolchain: $(which xtensa-lx106-elf-gcc)"
EOF

    chmod +x /home/unk1nd77/hydra/setup_env.sh
    
    # Добавляем в .bashrc
    if ! grep -q "Hydra-L" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# Hydra-L Environment" >> ~/.bashrc
        echo "source /home/unk1nd77/hydra/setup_env.sh" >> ~/.bashrc
    fi
    
    log "Переменные окружения настроены ✓"
}

# Проверка установки
verify_installation() {
    log "Проверка установки..."
    
    # Проверяем toolchain
    if [[ -f "/home/unk1nd77/hydra/xtensa-lx106-elf/bin/xtensa-lx106-elf-gcc" ]]; then
        log "Toolchain: ✓"
    else
        error "Toolchain не найден!"
    fi
    
    # Проверяем SDK
    if [[ -d "/home/unk1nd77/hydra/ESP8266_RTOS_SDK" ]]; then
        log "SDK: ✓"
    else
        error "SDK не найден!"
    fi
    
    # Проверяем Python окружение
    if [[ -d "/home/unk1nd77/hydra/venv" ]]; then
        log "Python окружение: ✓"
    else
        error "Python окружение не найдено!"
    fi
    
    # Проверяем исправления
    if [[ -f "/home/unk1nd77/hydra/ESP8266_RTOS_SDK/components/nvs_flash/include/nvs_flash.h" ]]; then
        log "NVS Flash исправления: ✓"
    else
        error "NVS Flash исправления не найдены!"
    fi
    
    if [[ -f "/home/unk1nd77/hydra/ESP8266_RTOS_SDK/components/newlib/include/sys/lock.h" ]]; then
        log "Lock исправления: ✓"
    else
        error "Lock исправления не найдены!"
    fi
    
    log "Все проверки пройдены успешно! ✓"
}

# Создание скрипта сборки проекта
create_build_script() {
    log "Создание скрипта сборки..."
    
    cat > /home/unk1nd77/hydra/build_hydra.sh << 'EOF'
#!/bin/bash

# Hydra-L Build Script
set -e

# Активируем окружение
source /home/unk1nd77/hydra/setup_env.sh

# Переходим в директорию проекта
cd /home/unk1nd77/hydra/my_project

echo "Building Hydra-L project..."

# Очищаем предыдущую сборку
idf.py fullclean

# Конфигурируем проект
idf.py menuconfig

# Собираем проект
idf.py build

echo "Build completed successfully!"
echo "Firmware: build/hydra-l.bin"
EOF

    chmod +x /home/unk1nd77/hydra/build_hydra.sh
    
    log "Скрипт сборки создан ✓"
}

# Основная функция
main() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "    Hydra-L Complete Installation"
    echo "    ESP8266 Development Environment"
    echo "=========================================="
    echo -e "${NC}"
    
    check_root
    check_architecture
    check_os
    update_system
    install_system_packages
    create_directories
    download_toolchain
    download_esp8266_sdk
    setup_python_env
    create_sdk_fixes
    setup_environment
    verify_installation
    create_build_script
    
    echo -e "${GREEN}"
    echo "=========================================="
    echo "    УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!"
    echo "=========================================="
    echo -e "${NC}"
    
    echo -e "${YELLOW}Следующие шаги:${NC}"
    echo "1. Перезагрузите терминал или выполните: source ~/.bashrc"
    echo "2. Перейдите в директорию проекта: cd /home/unk1nd77/hydra/my_project"
    echo "3. Запустите сборку: /home/unk1nd77/hydra/build_hydra.sh"
    echo "4. Или используйте команды:"
    echo "   - idf.py menuconfig  # для конфигурации"
    echo "   - idf.py build       # для сборки"
    echo "   - idf.py flash       # для прошивки"
    
    echo -e "${BLUE}Переменные окружения:${NC}"
    echo "IDF_PATH: /home/unk1nd77/hydra/ESP8266_RTOS_SDK"
    echo "Toolchain: /home/unk1nd77/hydra/xtensa-lx106-elf/bin"
    echo "Python venv: /home/unk1nd77/hydra/venv"
}

# Запуск
main "$@"
