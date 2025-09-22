# 🚀 Hydra-L Complete Installation Guide

Полное руководство по установке ESP8266 проекта Hydra-L на чистую Linux систему.

## 📋 Системные требования

### Минимальные требования
- **ОС**: Ubuntu 18.04+ / Debian 9+ / Linux Mint 19+
- **Архитектура**: x86_64 (AMD64)
- **RAM**: 4GB (рекомендуется 8GB+)
- **Диск**: 10GB свободного места
- **Интернет**: стабильное соединение

### Поддерживаемые дистрибутивы
- ✅ Ubuntu 18.04, 20.04, 22.04
- ✅ Debian 9, 10, 11
- ✅ Linux Mint 19, 20, 21
- ⚠️ CentOS/RHEL (требует дополнительной настройки)
- ⚠️ Arch Linux (требует дополнительной настройки)

## 🚀 Быстрая установка

### Автоматическая установка (рекомендуется)

```bash
# Скачайте и запустите скрипт установки
wget https://raw.githubusercontent.com/your-repo/hydra-l/main/install_hydra_complete.sh
chmod +x install_hydra_complete.sh
./install_hydra_complete.sh
```

### Ручная установка

Если автоматическая установка не работает, следуйте пошаговой инструкции ниже.

## 📦 Пошаговая установка

### Шаг 1: Подготовка системы

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка основных пакетов
sudo apt install -y \
    build-essential \
    cmake \
    ninja-build \
    git \
    wget \
    curl \
    unzip \
    python3 \
    python3-pip \
    python3-venv \
    python3-setuptools
```

### Шаг 2: Установка библиотек разработки

```bash
# Библиотеки для компиляции
sudo apt install -y \
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
```

### Шаг 3: Создание рабочих директорий

```bash
# Создание основной директории
mkdir -p /home/unk1nd77/hydra
cd /home/unk1nd77/hydra
```

### Шаг 4: Установка ESP8266 Toolchain

```bash
# Создание директории для toolchain
mkdir -p xtensa-lx106-elf

# Загрузка toolchain (замените URL на актуальный)
wget -O toolchain.tar.gz "https://github.com/espressif/crosstool-NG/releases/download/xtensa-1.22.0/xtensa-lx106-elf-5.2.0.tar.gz"

# Распаковка
tar -xzf toolchain.tar.gz -C xtensa-lx106-elf --strip-components=1
rm toolchain.tar.gz

# Исправление g++ wrapper
mv xtensa-lx106-elf/bin/xtensa-lx106-elf-g++ xtensa-lx106-elf/bin/xtensa-lx106-elf-g++.wrapper
cp xtensa-lx106-elf/bin/xtensa-lx106-elf-gcc xtensa-lx106-elf/bin/xtensa-lx106-elf-g++
```

### Шаг 5: Установка ESP8266 RTOS SDK

```bash
# Клонирование SDK
git clone --recursive https://github.com/espressif/ESP8266_RTOS_SDK.git
```

### Шаг 6: Настройка Python окружения

```bash
# Создание виртуального окружения
python3 -m venv venv
source venv/bin/activate

# Обновление pip
pip install --upgrade pip

# Установка Python пакетов
pip install \
    pyyaml \
    click \
    pyparsing \
    pyelftools \
    cryptography \
    future \
    pycryptodome
```

### Шаг 7: Применение исправлений SDK

Скрипт автоматически создаст необходимые исправления:

1. **NVS Flash компонент** - заглушки для совместимости
2. **Lock механизмы** - заглушки для sys/lock.h
3. **LWIP исправления** - обновление include путей
4. **Wear Levelling исправления** - исправление format specifiers

### Шаг 8: Настройка переменных окружения

```bash
# Создание файла окружения
cat > setup_env.sh << 'EOF'
#!/bin/bash
export PATH="/home/unk1nd77/hydra/xtensa-lx106-elf/bin:$PATH"
export IDF_PATH="/home/unk1nd77/hydra/ESP8266_RTOS_SDK"
export ESP8266_RTOS_SDK_PATH="/home/unk1nd77/hydra/ESP8266_RTOS_SDK"
source /home/unk1nd77/hydra/venv/bin/activate
echo "Hydra-L environment activated!"
EOF

chmod +x setup_env.sh

# Добавление в .bashrc
echo "source /home/unk1nd77/hydra/setup_env.sh" >> ~/.bashrc
```

## ✅ Проверка установки

### Автоматическая проверка

```bash
# Запуск скрипта проверки
./check_installation.sh
```

### Ручная проверка

```bash
# Активация окружения
source setup_env.sh

# Проверка toolchain
xtensa-lx106-elf-gcc --version

# Проверка SDK
idf.py --version

# Проверка Python пакетов
python3 -c "import yaml, click, pyparsing"
```

## 🔧 Использование

### Сборка проекта

```bash
# Переход в директорию проекта
cd /home/unk1nd77/hydra/my_project

# Активация окружения
source /home/unk1nd77/hydra/setup_env.sh

# Конфигурация проекта
idf.py menuconfig

# Сборка
idf.py build

# Прошивка (подключите ESP8266)
idf.py flash
```

### Использование скриптов

```bash
# Быстрая сборка
/home/unk1nd77/hydra/build_hydra.sh

# Проверка установки
/home/unk1nd77/hydra/check_installation.sh
```

## 🐛 Устранение проблем

### Проблема: "command not found: idf.py"

**Решение:**
```bash
source /home/unk1nd77/hydra/setup_env.sh
```

### Проблема: "xtensa-lx106-elf-gcc: No such file or directory"

**Решение:**
```bash
# Проверьте установку toolchain
ls -la /home/unk1nd77/hydra/xtensa-lx106-elf/bin/

# Переустановите toolchain
rm -rf xtensa-lx106-elf
# Повторите шаг 4
```

### Проблема: "Python package not found"

**Решение:**
```bash
# Активируйте виртуальное окружение
source /home/unk1nd77/hydra/venv/bin/activate

# Переустановите пакеты
pip install -r /home/unk1nd77/hydra/ESP8266_RTOS_SDK/requirements.txt
```

### Проблема: "menuconfig не работает"

**Решение:**
```bash
# Установите ncurses
sudo apt install -y libncurses5-dev libncursesw5-dev

# Установите дополнительные инструменты
sudo apt install -y flex bison gperf
```

## 📁 Структура установки

```
/home/unk1nd77/hydra/
├── xtensa-lx106-elf/          # ESP8266 Toolchain
│   └── bin/                   # Компиляторы и утилиты
├── ESP8266_RTOS_SDK/          # ESP8266 RTOS SDK
│   ├── components/            # Компоненты SDK
│   │   ├── nvs_flash/         # NVS Flash (исправления)
│   │   └── newlib/            # Newlib (исправления)
│   └── tools/                 # Инструменты SDK
├── venv/                      # Python виртуальное окружение
├── my_project/                # Проект Hydra-L
├── setup_env.sh              # Скрипт активации окружения
├── build_hydra.sh            # Скрипт сборки
├── check_installation.sh     # Скрипт проверки
└── install_hydra_complete.sh # Скрипт установки
```

## 🔄 Обновление

### Обновление SDK

```bash
cd /home/unk1nd77/hydra/ESP8266_RTOS_SDK
git pull
git submodule update --recursive
```

### Обновление Python пакетов

```bash
source /home/unk1nd77/hydra/venv/bin/activate
pip install --upgrade -r /home/unk1nd77/hydra/ESP8266_RTOS_SDK/requirements.txt
```

## 🗑️ Удаление

### Полное удаление

```bash
# Удаление директории проекта
rm -rf /home/unk1nd77/hydra

# Удаление из .bashrc
sed -i '/Hydra-L/d' ~/.bashrc
```

### Частичное удаление

```bash
# Удаление только build файлов
rm -rf /home/unk1nd77/hydra/my_project/build

# Очистка кэша
idf.py fullclean
```

## 📞 Поддержка

Если у вас возникли проблемы:

1. Запустите `./check_installation.sh` для диагностики
2. Проверьте логи установки
3. Убедитесь, что все зависимости установлены
4. Попробуйте переустановку

## 📝 Changelog

### v1.0.0
- Первоначальная версия
- Автоматическая установка всех зависимостей
- Исправления для ESP8266 RTOS SDK
- Полная проверка установки

---

**Примечание**: Этот скрипт создан для автоматизации установки ESP8266 проекта Hydra-L. Все исправления применяются автоматически и не требуют ручного вмешательства.
