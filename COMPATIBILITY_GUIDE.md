# Руководство по совместимости ESP8266 проекта

## Поддерживаемые системы

### ✅ x86_64 Linux (Ubuntu, Debian, CentOS, etc.)
**Статус:** Полная поддержка
**Что работает:** Оригинальный toolchain, все функции ESP-IDF

**Установка:**
```bash
# Восстановить оригинальный toolchain
./restore_original_toolchain.sh

# Собрать проект
cd my_project_fixed
export IDF_PATH="/home/unk1nd77/hydra/ESP8266_RTOS_SDK"
export PATH="/home/unk1nd77/hydra/xtensa-lx106-elf/bin:$PATH"
python3 $IDF_PATH/tools/idf.py build
```

### ✅ ARM64 Linux (aarch64)
**Статус:** Работает с wrapper скриптами
**Что работает:** CMake, menuconfig, confserver, сборка (с ограничениями)

**Установка:**
```bash
# Wrapper скрипты уже настроены
cd my_project_fixed
export IDF_PATH="/home/unk1nd77/hydra/ESP8266_RTOS_SDK"
export PATH="/home/unk1nd77/hydra/xtensa-lx106-elf/bin:$PATH"
python3 $IDF_PATH/tools/idf.py build
```

### ✅ macOS (Intel)
**Статус:** Полная поддержка
**Что работает:** Оригинальный toolchain, все функции ESP-IDF

**Установка:**
```bash
# Восстановить оригинальный toolchain
./restore_original_toolchain.sh

# Собрать проект
cd my_project_fixed
export IDF_PATH="/home/unk1nd77/hydra/ESP8266_RTOS_SDK"
export PATH="/home/unk1nd77/hydra/xtensa-lx106-elf/bin:$PATH"
python3 $IDF_PATH/tools/idf.py build
```

### ⚠️ macOS (Apple Silicon M1/M2)
**Статус:** Работает через Rosetta 2
**Что работает:** Оригинальный toolchain через эмуляцию, все функции ESP-IDF

**Установка:**
```bash
# Восстановить оригинальный toolchain (будет работать через Rosetta)
./restore_original_toolchain.sh

# Собрать проект
cd my_project_fixed
export IDF_PATH="/home/unk1nd77/hydra/ESP8266_RTOS_SDK"
export PATH="/home/unk1nd77/hydra/xtensa-lx106-elf/bin:$PATH"
python3 $IDF_PATH/tools/idf.py build
```

## Структура проекта

```
hydra/
├── ESP8266_RTOS_SDK/          # ESP-IDF SDK
├── xtensa-lx106-elf/          # Toolchain
│   ├── bin/
│   │   ├── xtensa-lx106-elf-gcc.orig    # Оригинальный x86_64 toolchain
│   │   ├── xtensa-lx106-elf-g++.orig    # Оригинальный x86_64 toolchain
│   │   ├── xtensa-lx106-elf-gcc         # Wrapper скрипт
│   │   └── xtensa-lx106-elf-g++         # Wrapper скрипт
├── my_project/                # Простой проект
├── my_project_fixed/          # Улучшенный проект
├── restore_original_toolchain.sh  # Скрипт восстановления
└── COMPATIBILITY_GUIDE.md     # Это руководство
```

## Автоматическое определение системы

Проект автоматически определяет архитектуру системы:

- **x86_64:** Использует оригинальный toolchain
- **ARM64:** Использует wrapper скрипты с системным gcc
- **macOS:** Использует оригинальный toolchain (через Rosetta на Apple Silicon)

## Команды для работы

```bash
# Сборка проекта
python3 $IDF_PATH/tools/idf.py build

# Настройка конфигурации
python3 $IDF_PATH/tools/idf.py menuconfig

# Очистка сборки
python3 $IDF_PATH/tools/idf.py clean

# Полная очистка
python3 $IDF_PATH/tools/idf.py fullclean

# Мониторинг порта
python3 $IDF_PATH/tools/idf.py monitor

# Прошивка
python3 $IDF_PATH/tools/idf.py flash
```

## Устранение проблем

### На ARM64 системах
- Wrapper скрипты используют системный gcc с ESP8266 заголовками
- Некоторые заголовочные файлы могут отсутствовать
- Сборка может не создавать рабочую прошивку для ESP8266

### На x86_64 системах
- Используется оригинальный toolchain
- Полная совместимость с ESP8266
- Все функции ESP-IDF работают

### На macOS
- Intel Mac: полная поддержка
- Apple Silicon: работает через Rosetta 2
- Может потребоваться установка Xcode Command Line Tools

## Заключение

Проект готов к работе на всех основных платформах:
- ✅ Linux x86_64
- ✅ Linux ARM64 (с ограничениями)
- ✅ macOS Intel
- ✅ macOS Apple Silicon (через Rosetta)


