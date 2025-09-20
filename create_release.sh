#!/bin/bash
# Скрипт для создания релизного архива проекта

set -e

# Цвета
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}📦 Создание релизного архива...${NC}"

# Получение версии из git или установка по умолчанию
VERSION=$(git describe --tags --always 2>/dev/null || echo "v1.0.0")
ARCHIVE_NAME="hydra-esp8266-${VERSION}.tar.gz"

echo -e "${YELLOW}Версия: $VERSION${NC}"
echo -e "${YELLOW}Архив: $ARCHIVE_NAME${NC}"

# Создание временной директории
TEMP_DIR=$(mktemp -d)
echo "📁 Временная директория: $TEMP_DIR"

# Копирование файлов проекта
echo "📋 Копирование файлов проекта..."
cp -r . "$TEMP_DIR/hydra-esp8266"

# Удаление ненужных файлов
echo "🧹 Очистка ненужных файлов..."
cd "$TEMP_DIR/hydra-esp8266"

# Удаление build директорий
rm -rf build/ */build/ **/build/ 2>/dev/null || true

# Удаление временных файлов
rm -f *.log errorlog.txt 2>/dev/null || true
rm -f *.tmp *.temp 2>/dev/null || true
rm -f ~$* 2>/dev/null || true

# Удаление backup директорий
rm -rf *_backup/ backup/ 2>/dev/null || true

# Удаление архивов
rm -f *.tar.gz *.zip *.rar 2>/dev/null || true

# Удаление документов
rm -f *.docx *.pdf 2>/dev/null || true

# Создание архива
echo "📦 Создание архива..."
cd "$TEMP_DIR"
tar -czf "$ARCHIVE_NAME" hydra-esp8266/

# Перемещение архива в рабочую директорию
mv "$ARCHIVE_NAME" "/home/unk1nd77/hydra/"

# Очистка временной директории
rm -rf "$TEMP_DIR"

# Проверка размера архива
ARCHIVE_SIZE=$(du -h "/home/unk1nd77/hydra/$ARCHIVE_NAME" | cut -f1)

echo -e "${GREEN}✅ Архив создан успешно!${NC}"
echo -e "${GREEN}📁 Файл: /home/unk1nd77/hydra/$ARCHIVE_NAME${NC}"
echo -e "${GREEN}📏 Размер: $ARCHIVE_SIZE${NC}"

# Информация о содержимом
echo ""
echo "📋 Содержимое архива:"
echo "├── install.sh                    # Универсальный скрипт установки"
echo "├── setup_env.sh                  # Скрипт настройки окружения"
echo "├── ESP8266_RTOS_SDK/             # ESP-IDF SDK"
echo "├── xtensa-lx106-elf/             # Toolchain"
echo "├── my_project/                   # Простой проект"
echo "├── my_project_fixed/             # Улучшенный проект"
echo "├── README.md                     # Документация"
echo "└── .gitignore                    # Git ignore файл"

echo ""
echo "🚀 Инструкции для пользователей:"
echo "1. Скачайте архив: $ARCHIVE_NAME"
echo "2. Распакуйте: tar -xzf $ARCHIVE_NAME"
echo "3. Перейдите в директорию: cd hydra-esp8266"
echo "4. Запустите установку: ./install.sh"
echo "5. Активируйте окружение: source setup_env.sh"
echo "6. Соберите проект: cd my_project_fixed && python3 \$IDF_PATH/tools/idf.py build"

echo ""
echo "🎉 Релиз готов к публикации!"
