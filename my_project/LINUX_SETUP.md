# Настройка для Linux

## Установка зависимостей

### Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install git wget flex bison gperf python3 python3-pip python3-setuptools cmake ninja-build ccache libffi-dev libssl-dev libncurses5-dev libncursesw5-dev
```

### Fedora/CentOS/RHEL:
```bash
# Для новых версий Fedora:
sudo dnf update
sudo dnf install git wget flex bison gperf python3 python3-pip python3-setuptools cmake ninja-build ccache libffi-devel openssl-devel ncurses-devel

# Для старых версий CentOS/RHEL:
sudo yum update
sudo yum install git wget flex bison gperf python3 python3-pip python3-setuptools cmake ninja-build ccache libffi-devel openssl-devel ncurses-devel
```

### Arch Linux:
```bash
sudo pacman -S git wget flex bison gperf python python-pip python-setuptools cmake ninja ccache libffi openssl ncurses
```

## Исправленные проблемы

✅ **Ошибки pthread** - полностью отключен C++ компилятор в CMakeLists.txt и sdkconfig.defaults
✅ **Ошибки CONFIG_FREERTOS_HZ** - исправлены в коде
✅ **Ошибки portTICK_PERIOD_MS** - исправлены в компонентах
✅ **Ошибки curses.h** - решено установкой ncurses-devel
✅ **Ошибки gperf** - решено установкой gperf

## Сборка проекта

После установки всех зависимостей:
```bash
cd /path/to/my_project
idf.py fullclean
idf.py build
```

## Прошивка

```bash
idf.py -p /dev/ttyUSB0 flash
# или
idf.py -p /dev/ttyACM0 flash
```

## Альтернативное решение (если curses не нужен)

Если menuconfig не нужен, можно создать пустой файл:
```bash
mkdir -p build/kconfig_bin
touch build/kconfig_bin/mconf-idf
chmod +x build/kconfig_bin/mconf-idf
```
