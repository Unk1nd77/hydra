#!/bin/bash

# =============================================================================
# Hydra-L Complete Installation Script (FIXED VERSION)
# Автоматическая установка всех зависимостей для ESP8266 проекта Hydra-L
# Исправлены все проблемы с библиотеками и toolchain
# БЕЗ ЗАГЛУШЕК - только официальные библиотеки!
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
        
        # Используем правильный URL для toolchain версии 8.4.0
        TOOLCHAIN_URL="https://github.com/espressif/crosstool-NG/releases/download/xtensa-1.22.0/xtensa-lx106-elf-8.4.0.tar.gz"
        
        log "Загрузка toolchain с $TOOLCHAIN_URL..."
        wget -O toolchain.tar.gz "$TOOLCHAIN_URL" || {
            error "Не удалось загрузить toolchain. Проверьте интернет соединение."
        }
        
        log "Распаковка toolchain..."
        tar -xzf toolchain.tar.gz -C xtensa-lx106-elf --strip-components=1
        rm toolchain.tar.gz
        
        # ИСПРАВЛЕНИЕ 1: Исправляем g++ wrapper
        if [[ -f "xtensa-lx106-elf/bin/xtensa-lx106-elf-g++" ]]; then
            log "Исправление g++ wrapper..."
            mv xtensa-lx106-elf/bin/xtensa-lx106-elf-g++ xtensa-lx106-elf/bin/xtensa-lx106-elf-g++.wrapper
            cp xtensa-lx106-elf/bin/xtensa-lx106-elf-gcc xtensa-lx106-elf/bin/xtensa-lx106-elf-g++
        fi
        
        # ИСПРАВЛЕНИЕ 2: Исправляем liblto_plugin.so
        if [[ -f "xtensa-lx106-elf/libexec/gcc/xtensa-lx106-elf/8.4.0/liblto_plugin.so.0.0.0" ]]; then
            log "Исправление liblto_plugin.so..."
            ln -sf liblto_plugin.so.0.0.0 xtensa-lx106-elf/libexec/gcc/xtensa-lx106-elf/8.4.0/liblto_plugin.so
        fi
        
        log "Toolchain установлен ✓"
    else
        log "Toolchain уже установлен ✓"
    fi
}

# Загрузка ESP8266 RTOS SDK
download_esp8266_sdk() {
    log "Загрузка официального ESP8266 RTOS SDK..."
    
    if [[ ! -d "ESP8266_RTOS_SDK_official" ]]; then
        SDK_URL="https://github.com/espressif/ESP8266_RTOS_SDK.git"
        
        log "Клонирование официального SDK с $SDK_URL..."
        git clone --recursive "$SDK_URL" ESP8266_RTOS_SDK_official || {
            error "Не удалось клонировать SDK. Проверьте интернет соединение."
        }
        
        # ИСПРАВЛЕНИЕ 3: Исправляем pthread CMakeLists.txt
        log "Исправление pthread CMakeLists.txt..."
        if [[ -f "ESP8266_RTOS_SDK_official/components/pthread/CMakeLists.txt" ]]; then
            sed -i 's/pthread_include_pthread_cond_impl/pthread_include_pthread_cond_var_impl/' ESP8266_RTOS_SDK_official/components/pthread/CMakeLists.txt
        fi
        
        log "Официальный SDK загружен ✓"
    else
        log "Официальный SDK уже загружен ✓"
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
    
    # Устанавливаем Python пакеты из официального SDK
    if [[ -f "ESP8266_RTOS_SDK_official/requirements.txt" ]]; then
        log "Установка Python пакетов из официального SDK..."
        pip install -r ESP8266_RTOS_SDK_official/requirements.txt
    else
        # Fallback пакеты
    pip install \
        pyyaml \
        click \
        pyparsing \
        pyelftools \
        cryptography \
        future \
        pycryptodome
    fi
    
    log "Python окружение настроено ✓"
}

# Создание символических ссылок для библиотек
create_library_links() {
    log "Создание символических ссылок для библиотек..."
    
    cd /home/unk1nd77/hydra
    
    # ИСПРАВЛЕНИЕ 4: Создаем символическую ссылку для libgcc.a
    if [[ -f "xtensa-lx106-elf/lib/gcc/xtensa-lx106-elf/8.4.0/libgcc.a" ]]; then
        mkdir -p ESP8266_RTOS_SDK_official/components/esp8266/lib
        ln -sf /home/unk1nd77/hydra/xtensa-lx106-elf/lib/gcc/xtensa-lx106-elf/8.4.0/libgcc.a ESP8266_RTOS_SDK_official/components/esp8266/lib/libgcc.a
        log "Создана ссылка для libgcc.a ✓"
    fi
    
    log "Символические ссылки созданы ✓"
}

# Создание переменных окружения
setup_environment() {
    log "Настройка переменных окружения..."
    
    # Создаем файл с переменными окружения
    cat > /home/unk1nd77/hydra/setup_env.sh << 'EOF'
#!/bin/bash
# Hydra-L Environment Setup

export PATH="/home/unk1nd77/hydra/xtensa-lx106-elf/bin:$PATH"
export IDF_PATH="/home/unk1nd77/hydra/ESP8266_RTOS_SDK_official"
export ESP8266_RTOS_SDK_PATH="/home/unk1nd77/hydra/ESP8266_RTOS_SDK_official"

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
    if [[ -d "/home/unk1nd77/hydra/ESP8266_RTOS_SDK_official" ]]; then
        log "Официальный SDK: ✓"
    else
        error "Официальный SDK не найден!"
    fi
    
    # Проверяем Python окружение
    if [[ -d "/home/unk1nd77/hydra/venv" ]]; then
        log "Python окружение: ✓"
    else
        error "Python окружение не найдено!"
    fi
    
    # Проверяем исправления
    if [[ -f "/home/unk1nd77/hydra/xtensa-lx106-elf/libexec/gcc/xtensa-lx106-elf/8.4.0/liblto_plugin.so" ]]; then
        log "liblto_plugin.so исправление: ✓"
    else
        error "liblto_plugin.so исправление не найдено!"
    fi
    
    if [[ -f "/home/unk1nd77/hydra/ESP8266_RTOS_SDK_official/components/esp8266/lib/libgcc.a" ]]; then
        log "libgcc.a ссылка: ✓"
    else
        error "libgcc.a ссылка не найдена!"
    fi
    
    # Проверяем pthread исправление
    if grep -q "pthread_include_pthread_cond_var_impl" /home/unk1nd77/hydra/ESP8266_RTOS_SDK_official/components/pthread/CMakeLists.txt; then
        log "pthread исправление: ✓"
    else
        error "pthread исправление не найдено!"
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
    create_library_links
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
    echo "IDF_PATH: /home/unk1nd77/hydra/ESP8266_RTOS_SDK_official"
    echo "Toolchain: /home/unk1nd77/hydra/xtensa-lx106-elf/bin"
    echo "Python venv: /home/unk1nd77/hydra/venv"
    
    echo -e "${GREEN}Исправления применены:${NC}"
    echo "✓ Исправлен g++ wrapper"
    echo "✓ Исправлен liblto_plugin.so"
    echo "✓ Создана ссылка на libgcc.a"
    echo "✓ Исправлен pthread CMakeLists.txt"
    echo "✓ Используется официальный SDK без заглушек"
}

# Запуск
main "$@"
