#!/bin/bash
# Скрипт для коммита проекта в git

set -e

# Цвета
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Подготовка к коммиту в git...${NC}"

# Проверка git
if ! command -v git >/dev/null 2>&1; then
    echo "❌ Git не найден. Установите git и повторите попытку."
    exit 1
fi

# Инициализация git репозитория (если не инициализирован)
if [ ! -d ".git" ]; then
    echo "📁 Инициализация git репозитория..."
    git init
fi

# Добавление всех файлов
echo "📝 Добавление файлов в git..."
git add .

# Проверка статуса
echo "📊 Статус git:"
git status

# Коммит
echo "💾 Создание коммита..."
git commit -m "feat: Add universal ESP8266 Hydra project with cross-platform support

- Add universal install.sh script for Linux x86_64, ARM64, macOS
- Add wrapper scripts for ARM64 compatibility
- Add restore_original_toolchain.sh for x86_64 systems
- Add comprehensive documentation and compatibility guide
- Add .gitignore for clean repository
- Support for all major platforms and architectures
- Ready-to-use project with one-command installation"

echo -e "${GREEN}✅ Коммит создан успешно!${NC}"

# Информация о следующих шагах
echo ""
echo "📋 Следующие шаги:"
echo "1. Добавьте удаленный репозиторий:"
echo "   git remote add origin <your-repo-url>"
echo ""
echo "2. Отправьте изменения:"
echo "   git push -u origin main"
echo ""
echo "3. Создайте релиз с архивом проекта"
echo ""
echo "🎉 Проект готов к публикации!"
