#!/bin/bash

# =============================================================================
# Hydra-L Installation Checker
# Проверка корректности установки всех компонентов
# =============================================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Счетчики
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Функция для проверки
check_item() {
    local name="$1"
    local command="$2"
    local expected="$3"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo -n "Проверка $name... "
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        if [[ -n "$expected" ]]; then
            echo "  Ожидалось: $expected"
        fi
        return 1
    fi
}

# Функция для проверки файла
check_file() {
    local file="$1"
    local description="$2"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo -n "Проверка $description... "
    
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        echo "  Файл не найден: $file"
        return 1
    fi
}

# Функция для проверки директории
check_dir() {
    local dir="$1"
    local description="$2"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo -n "Проверка $description... "
    
    if [[ -d "$dir" ]]; then
        echo -e "${GREEN}✓${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        echo "  Директория не найдена: $dir"
        return 1
    fi
}

# Функция для проверки команды с выводом версии
check_version() {
    local name="$1"
    local command="$2"
    local version_pattern="$3"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo -n "Проверка $name... "
    
    if output=$(eval "$command" 2>/dev/null); then
        if [[ -n "$version_pattern" ]] && echo "$output" | grep -q "$version_pattern"; then
            echo -e "${GREEN}✓${NC} ($(echo "$output" | head -1))"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            return 0
        elif [[ -z "$version_pattern" ]]; then
            echo -e "${GREEN}✓${NC}"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            return 0
        else
            echo -e "${YELLOW}⚠${NC} (версия не соответствует ожидаемой)"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            return 1
        fi
    else
        echo -e "${RED}✗${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

echo -e "${BLUE}"
echo "=========================================="
echo "    Hydra-L Installation Checker"
echo "=========================================="
echo -e "${NC}"

# Активируем окружение
if [[ -f "/home/unk1nd77/hydra/setup_env.sh" ]]; then
    source /home/unk1nd77/hydra/setup_env.sh 2>/dev/null || {
        echo -e "${YELLOW}Не удалось активировать окружение, продолжаем без него...${NC}"
    }
else
    echo -e "${YELLOW}Файл setup_env.sh не найден, настраиваем переменные вручную...${NC}"
    export PATH="/home/unk1nd77/hydra/xtensa-lx106-elf/bin:$PATH"
    export IDF_PATH="/home/unk1nd77/hydra/ESP8266_RTOS_SDK"
    export ESP8266_RTOS_SDK_PATH="/home/unk1nd77/hydra/ESP8266_RTOS_SDK"
fi

echo -e "${YELLOW}Проверка системных зависимостей...${NC}"

# Системные пакеты
check_version "Python 3" "python3 --version" "Python 3"
check_version "pip" "pip --version" "pip"
check_version "cmake" "cmake --version" "cmake"
check_version "ninja" "ninja --version" ""
check_version "git" "git --version" "git"
check_version "wget" "wget --version" "wget"
check_version "flex" "flex --version" "flex"
check_version "bison" "bison --version" "bison"
check_version "gperf" "gperf --version" "gperf"

echo -e "${YELLOW}Проверка ESP8266 Toolchain...${NC}"

# Toolchain
check_file "/home/unk1nd77/hydra/xtensa-lx106-elf/bin/xtensa-lx106-elf-gcc" "ESP8266 GCC"
check_file "/home/unk1nd77/hydra/xtensa-lx106-elf/bin/xtensa-lx106-elf-g++" "ESP8266 G++"
check_file "/home/unk1nd77/hydra/xtensa-lx106-elf/bin/xtensa-lx106-elf-objdump" "ESP8266 objdump"
check_file "/home/unk1nd77/hydra/xtensa-lx106-elf/bin/xtensa-lx106-elf-objcopy" "ESP8266 objcopy"
check_file "/home/unk1nd77/hydra/xtensa-lx106-elf/bin/xtensa-lx106-elf-nm" "ESP8266 nm"
check_file "/home/unk1nd77/hydra/xtensa-lx106-elf/bin/xtensa-lx106-elf-ar" "ESP8266 ar"
check_file "/home/unk1nd77/hydra/xtensa-lx106-elf/bin/xtensa-lx106-elf-ranlib" "ESP8266 ranlib"
check_file "/home/unk1nd77/hydra/xtensa-lx106-elf/bin/xtensa-lx106-elf-ld" "ESP8266 ld"
check_file "/home/unk1nd77/hydra/xtensa-lx106-elf/bin/xtensa-lx106-elf-as" "ESP8266 as"

# Проверяем версию toolchain
check_version "ESP8266 GCC Version" "xtensa-lx106-elf-gcc --version" "xtensa-lx106-elf-gcc"

echo -e "${YELLOW}Проверка ESP8266 RTOS SDK...${NC}"

# SDK
check_dir "/home/unk1nd77/hydra/ESP8266_RTOS_SDK" "ESP8266 RTOS SDK"
check_file "/home/unk1nd77/hydra/ESP8266_RTOS_SDK/tools/idf.py" "IDF.py"
check_file "/home/unk1nd77/hydra/ESP8266_RTOS_SDK/requirements.txt" "Python requirements"

echo -e "${YELLOW}Проверка исправлений SDK...${NC}"

# NVS Flash исправления
check_file "/home/unk1nd77/hydra/ESP8266_RTOS_SDK/components/nvs_flash/include/nvs_flash.h" "NVS Flash header"
check_file "/home/unk1nd77/hydra/ESP8266_RTOS_SDK/components/nvs_flash/src/nvs_flash.c" "NVS Flash source"
check_file "/home/unk1nd77/hydra/ESP8266_RTOS_SDK/components/nvs_flash/CMakeLists.txt" "NVS Flash CMakeLists"

# Lock исправления
check_file "/home/unk1nd77/hydra/ESP8266_RTOS_SDK/components/newlib/include/sys/lock.h" "Lock header"

# LWIP исправления
check_file "/home/unk1nd77/hydra/ESP8266_RTOS_SDK/components/lwip/CMakeLists.txt" "LWIP CMakeLists"

echo -e "${YELLOW}Проверка Python окружения...${NC}"

# Python виртуальное окружение
check_dir "/home/unk1nd77/hydra/venv" "Python virtual environment"
check_file "/home/unk1nd77/hydra/venv/bin/activate" "Python venv activate"

# Python пакеты
check_item "pyyaml" "python3 -c 'import yaml'"
check_item "click" "python3 -c 'import click'"
check_item "pyparsing" "python3 -c 'import pyparsing'"
check_item "pyelftools" "python3 -c 'import elftools'"
check_item "cryptography" "python3 -c 'import cryptography'"
check_item "future" "python3 -c 'import future'"

echo -e "${YELLOW}Проверка переменных окружения...${NC}"

# Переменные окружения
check_item "IDF_PATH" "[[ -n \"\$IDF_PATH\" ]]"
check_item "ESP8266_RTOS_SDK_PATH" "[[ -n \"\$ESP8266_RTOS_SDK_PATH\" ]]"
check_item "Toolchain in PATH" "which xtensa-lx106-elf-gcc"

echo -e "${YELLOW}Проверка скриптов...${NC}"

# Скрипты
check_file "/home/unk1nd77/hydra/setup_env.sh" "Environment setup script"
check_file "/home/unk1nd77/hydra/build_hydra.sh" "Build script"
check_file "/home/unk1nd77/hydra/install_hydra_complete.sh" "Installation script"

echo -e "${YELLOW}Проверка проекта...${NC}"

# Проект
check_dir "/home/unk1nd77/hydra/my_project" "Hydra-L project"
check_file "/home/unk1nd77/hydra/my_project/main/main.c" "Main source file"
check_file "/home/unk1nd77/hydra/my_project/CMakeLists.txt" "Project CMakeLists"

echo -e "${BLUE}"
echo "=========================================="
echo "    РЕЗУЛЬТАТЫ ПРОВЕРКИ"
echo "=========================================="
echo -e "${NC}"

echo "Всего проверок: $TOTAL_CHECKS"
echo -e "Успешно: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "Неудачно: ${RED}$FAILED_CHECKS${NC}"

if [[ $FAILED_CHECKS -eq 0 ]]; then
    echo -e "${GREEN}"
    echo "=========================================="
    echo "    ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ УСПЕШНО!"
    echo "    Система готова к работе!"
    echo "=========================================="
    echo -e "${NC}"
    
    echo -e "${YELLOW}Следующие шаги:${NC}"
    echo "1. cd /home/unk1nd77/hydra/my_project"
    echo "2. idf.py menuconfig  # для конфигурации"
    echo "3. idf.py build       # для сборки"
    echo "4. idf.py flash       # для прошивки"
    
    exit 0
else
    echo -e "${RED}"
    echo "=========================================="
    echo "    ОБНАРУЖЕНЫ ПРОБЛЕМЫ!"
    echo "    Запустите установку заново:"
    echo "    /home/unk1nd77/hydra/install_hydra_complete.sh"
    echo "=========================================="
    echo -e "${NC}"
    
    exit 1
fi
