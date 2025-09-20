# 🚀 Быстрый старт ESP8266 проекта Hydra

## 📥 Скачивание и установка

### Вариант 1: Из архива (рекомендуется)
```bash
# Скачайте архив
wget <ссылка_на_архив>

# Распакуйте
tar -xzf hydra-esp8266-*.tar.gz
cd hydra-esp8266

# Запустите установку
chmod +x install.sh
./install.sh
```

### Вариант 2: Из git репозитория
```bash
# Клонируйте репозиторий
git clone <repository_url>
cd hydra

# Запустите установку
chmod +x install.sh
./install.sh
```

## 🔧 Настройка окружения

```bash
# Активируйте окружение
source setup_env.sh

# Проверьте установку
echo "IDF_PATH: $IDF_PATH"
which xtensa-lx106-elf-gcc
```

## 🏗️ Сборка проекта

```bash
# Перейдите в проект
cd my_project_fixed

# Соберите проект
python3 $IDF_PATH/tools/idf.py build

# Настройте конфигурацию (опционально)
python3 $IDF_PATH/tools/idf.py menuconfig
```

## 📱 Прошивка устройства

```bash
# Подключите ESP8266 к USB порту
# Определите порт (обычно /dev/ttyUSB0 или /dev/ttyACM0)

# Прошейте устройство
python3 $IDF_PATH/tools/idf.py -p /dev/ttyUSB0 flash

# Мониторинг
python3 $IDF_PATH/tools/idf.py -p /dev/ttyUSB0 monitor
```

## 🎯 Основные команды

```bash
# Сборка
python3 $IDF_PATH/tools/idf.py build

# Очистка
python3 $IDF_PATH/tools/idf.py clean

# Полная очистка
python3 $IDF_PATH/tools/idf.py fullclean

# Настройка
python3 $IDF_PATH/tools/idf.py menuconfig

# Прошивка
python3 $IDF_PATH/tools/idf.py flash

# Мониторинг
python3 $IDF_PATH/tools/idf.py monitor

# Сборка + прошивка + мониторинг
python3 $IDF_PATH/tools/idf.py build flash monitor
```

## 🖥️ Поддерживаемые системы

- ✅ **Linux x86_64** (Ubuntu, Debian, CentOS)
- ✅ **Linux ARM64** (aarch64)
- ✅ **macOS Intel**
- ✅ **macOS Apple Silicon** (через Rosetta)

## 🔧 Устранение проблем

### Ошибка "python: command not found"
```bash
# Создайте симлинк
sudo ln -s /usr/bin/python3 /usr/bin/python
```

### Ошибка "toolchain not found"
```bash
# Проверьте PATH
echo $PATH

# Активируйте окружение
source setup_env.sh
```

### Ошибка сборки на ARM64
- Проект использует wrapper скрипты для совместимости
- Некоторые заголовочные файлы могут отсутствовать
- Сборка может не создавать рабочую прошивку

### Ошибка "menuconfig: display too small"
- Увеличьте размер терминала
- Используйте `confserver` вместо `menuconfig`

## 📚 Дополнительная документация

- `README.md` - Основная документация
- `COMPATIBILITY_GUIDE.md` - Руководство по совместимости
- `my_project_fixed/docs/` - Документация проекта

## 🆘 Поддержка

При возникновении проблем:
1. Проверьте логи установки
2. Убедитесь, что все зависимости установлены
3. Проверьте версию Python (требуется 3.6+)
4. Обратитесь к документации ESP-IDF

## 🎉 Готово!

Проект готов к использованию! Теперь вы можете:
- Собирать прошивку для ESP8266
- Настраивать конфигурацию
- Прошивать устройство
- Мониторить работу

**Удачной разработки!** 🚀
