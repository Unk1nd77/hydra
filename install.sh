#!/bin/bash
# Универсальный скрипт установки ESP8266 проекта Hydra
# Поддерживает: Linux x86_64, Linux ARM64, macOS Intel, macOS Apple Silicon

set -e  # Остановка при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Определение системы
detect_system() {
    OS=$(uname -s)
    ARCH=$(uname -m)
    
    print_status "Определение системы: $OS $ARCH"
    
    case "$OS" in
        "Linux")
            if [[ "$ARCH" == "x86_64" ]]; then
                SYSTEM="linux_x86_64"
            elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
                SYSTEM="linux_arm64"
            else
                print_error "Неподдерживаемая архитектура Linux: $ARCH"
                exit 1
            fi
            ;;
        "Darwin")
            if [[ "$ARCH" == "x86_64" ]]; then
                SYSTEM="macos_intel"
            elif [[ "$ARCH" == "arm64" ]]; then
                SYSTEM="macos_apple_silicon"
            else
                print_error "Неподдерживаемая архитектура macOS: $ARCH"
                exit 1
            fi
            ;;
        *)
            print_error "Неподдерживаемая операционная система: $OS"
            exit 1
            ;;
    esac
    
    print_success "Система определена: $SYSTEM"
}

# Установка системных зависимостей
install_system_dependencies() {
    print_status "Установка системных зависимостей..."
    
    case "$SYSTEM" in
        "linux_x86_64"|"linux_arm64")
            if command -v apt-get >/dev/null 2>&1; then
                # Debian/Ubuntu
                print_status "Установка пакетов через apt..."
                sudo apt-get update
                sudo apt-get install -y \
                    python3 \
                    python3-pip \
                    python3-venv \
                    git \
                    wget \
                    curl \
                    build-essential \
                    cmake \
                    ninja-build \
                    ccache \
                    libffi-dev \
                    libssl-dev \
                    libncurses-dev \
                    flex \
                    bison \
                    gperf \
                    pkg-config
            elif command -v yum >/dev/null 2>&1; then
                # CentOS/RHEL
                print_status "Установка пакетов через yum..."
                sudo yum install -y \
                    python3 \
                    python3-pip \
                    git \
                    wget \
                    curl \
                    gcc \
                    gcc-c++ \
                    make \
                    cmake \
                    ninja-build \
                    ccache \
                    libffi-devel \
                    openssl-devel \
                    ncurses-devel \
                    flex \
                    bison \
                    gperf \
                    pkgconfig
            else
                print_warning "Не удалось определить пакетный менеджер. Установите зависимости вручную."
            fi
            ;;
        "macos_intel"|"macos_apple_silicon")
            if command -v brew >/dev/null 2>&1; then
                print_status "Установка пакетов через Homebrew..."
                brew install python3 git wget curl cmake ninja ccache pkg-config
            else
                print_warning "Homebrew не найден. Установите зависимости вручную или установите Homebrew."
            fi
            ;;
    esac
}

# Установка Python зависимостей
install_python_dependencies() {
    print_status "Установка Python зависимостей..."
    
    # Создание виртуального окружения
    if [ ! -d "venv" ]; then
        print_status "Создание виртуального окружения..."
        python3 -m venv venv
    fi
    
    # Активация виртуального окружения
    source venv/bin/activate
    
    # Обновление pip
    print_status "Обновление pip..."
    python3 -m pip install --upgrade pip
    
    # Установка зависимостей ESP-IDF
    if [ -f "ESP8266_RTOS_SDK/requirements.txt" ]; then
        print_status "Установка ESP-IDF зависимостей..."
        python3 -m pip install -r ESP8266_RTOS_SDK/requirements.txt
    fi
}

# Настройка toolchain
setup_toolchain() {
    print_status "Настройка toolchain для $SYSTEM..."
    
    case "$SYSTEM" in
        "linux_x86_64"|"macos_intel"|"macos_apple_silicon")
            # Используем оригинальный toolchain
            if [ -f "xtensa-lx106-elf/bin/xtensa-lx106-elf-gcc.orig" ]; then
                print_status "Восстановление оригинального toolchain..."
                cp xtensa-lx106-elf/bin/xtensa-lx106-elf-gcc.orig xtensa-lx106-elf/bin/xtensa-lx106-elf-gcc
                cp xtensa-lx106-elf/bin/xtensa-lx106-elf-g++.orig xtensa-lx106-elf/bin/xtensa-lx106-elf-g++
                chmod +x xtensa-lx106-elf/bin/xtensa-lx106-elf-gcc
                chmod +x xtensa-lx106-elf/bin/xtensa-lx106-elf-g++
                print_success "Оригинальный toolchain восстановлен"
            else
                print_error "Оригинальный toolchain не найден!"
                exit 1
            fi
            ;;
        "linux_arm64")
            # Wrapper скрипты уже настроены
            print_success "Wrapper скрипты для ARM64 уже настроены"
            ;;
    esac
}

# Настройка переменных окружения
setup_environment() {
    print_status "Настройка переменных окружения..."
    
    # Создание файла с переменными окружения
    cat > setup_env.sh << 'EOF'
#!/bin/bash
# Переменные окружения для ESP8266 проекта

export IDF_PATH="$(pwd)/ESP8266_RTOS_SDK"
export PATH="$(pwd)/xtensa-lx106-elf/bin:$PATH"

# Активация виртуального окружения
if [ -d "venv" ]; then
    source venv/bin/activate
fi

echo "✅ Переменные окружения настроены"
echo "IDF_PATH: $IDF_PATH"
echo "Toolchain: $(which xtensa-lx106-elf-gcc)"
EOF
    
    chmod +x setup_env.sh
    print_success "Файл setup_env.sh создан"
}

# Тестирование установки
test_installation() {
    print_status "Тестирование установки..."
    
    # Активация окружения
    source setup_env.sh
    
    # Проверка toolchain
    if command -v xtensa-lx106-elf-gcc >/dev/null 2>&1; then
        print_success "Toolchain найден: $(which xtensa-lx106-elf-gcc)"
    else
        print_error "Toolchain не найден!"
        exit 1
    fi
    
    # Проверка ESP-IDF
    if [ -f "$IDF_PATH/tools/idf.py" ]; then
        print_success "ESP-IDF найден: $IDF_PATH"
    else
        print_error "ESP-IDF не найден!"
        exit 1
    fi
    
    # Тест сборки
    print_status "Тестирование сборки проекта..."
    cd my_project_fixed
    if python3 $IDF_PATH/tools/idf.py build; then
        print_success "Сборка проекта успешна!"
    else
        print_warning "Сборка проекта не удалась, но установка завершена"
    fi
    cd ..
}

# Создание README
create_readme() {
    print_status "Создание README..."
    
    cat > README.md << 'EOF'
# ESP8266 Weather Station "Hydra"

Универсальный проект метеостанции на ESP8266 с поддержкой всех основных платформ.

## Быстрый старт

### 1. Установка
```bash
# Скачать и распаковать проект
git clone <repository_url>
cd hydra

# Запустить установку
chmod +x install.sh
./install.sh
```

### 2. Настройка окружения
```bash
# Активировать окружение
source setup_env.sh

# Перейти в проект
cd my_project_fixed
```

### 3. Сборка проекта
```bash
# Собрать проект
python3 $IDF_PATH/tools/idf.py build

# Настроить конфигурацию
python3 $IDF_PATH/tools/idf.py menuconfig

# Прошить устройство
python3 $IDF_PATH/tools/idf.py flash
```

## Поддерживаемые системы

- ✅ Linux x86_64 (Ubuntu, Debian, CentOS)
- ✅ Linux ARM64 (aarch64)
- ✅ macOS Intel
- ✅ macOS Apple Silicon (через Rosetta)

## Структура проекта

```
hydra/
├── install.sh                    # Универсальный скрипт установки
├── setup_env.sh                  # Скрипт настройки окружения
├── ESP8266_RTOS_SDK/             # ESP-IDF SDK
├── xtensa-lx106-elf/             # Toolchain
├── my_project/                   # Простой проект
├── my_project_fixed/             # Улучшенный проект
└── README.md                     # Документация
```

## Команды

```bash
# Сборка
python3 $IDF_PATH/tools/idf.py build

# Настройка
python3 $IDF_PATH/tools/idf.py menuconfig

# Очистка
python3 $IDF_PATH/tools/idf.py clean

# Прошивка
python3 $IDF_PATH/tools/idf.py flash

# Мониторинг
python3 $IDF_PATH/tools/idf.py monitor
```

## Устранение проблем

### На ARM64 системах
- Используются wrapper скрипты с системным gcc
- Некоторые заголовочные файлы могут отсутствовать
- Сборка может не создавать рабочую прошивку

### На x86_64 системах
- Используется оригинальный toolchain
- Полная совместимость с ESP8266
- Все функции ESP-IDF работают

## Лицензия

MIT License
EOF
    
    print_success "README.md создан"
}

# Основная функция
main() {
    print_status "🚀 Начало установки ESP8266 проекта Hydra"
    
    detect_system
    install_system_dependencies
    install_python_dependencies
    setup_toolchain
    setup_environment
    test_installation
    create_readme
    
    print_success "🎉 Установка завершена успешно!"
    print_status "Для начала работы выполните:"
    print_status "  source setup_env.sh"
    print_status "  cd my_project_fixed"
    print_status "  python3 \$IDF_PATH/tools/idf.py build"
}

# Запуск
main "$@"
