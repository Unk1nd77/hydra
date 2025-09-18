#!/bin/bash

# Простой скрипт для изменения ссылки на GitHub

echo "🔗 Изменение ссылки на GitHub"
echo "============================="

# Текущая ссылка
OLD_REPO="https://github.com/Unk1nd77/hydra-l-esp8266.git"
OLD_USER="Unk1nd77"
OLD_REPO_NAME="hydra-l-esp8266"

echo "Текущая ссылка: $OLD_REPO"
echo ""

# Запрашиваем новую ссылку
echo "Введите новую ссылку на GitHub репозиторий:"
echo "Пример: https://github.com/username/repository.git"
read -p "Новая ссылка: " NEW_REPO

if [ -z "$NEW_REPO" ]; then
    echo "❌ Ошибка: Ссылка не может быть пустой"
    exit 1
fi

# Извлекаем username и repository name из новой ссылки
if [[ $NEW_REPO =~ https://github.com/([^/]+)/([^/]+)\.git ]]; then
    NEW_USER="${BASH_REMATCH[1]}"
    NEW_REPO_NAME="${BASH_REMATCH[2]}"
else
    echo "❌ Ошибка: Неверный формат ссылки GitHub"
    echo "Используйте формат: https://github.com/username/repository.git"
    exit 1
fi

echo ""
echo "📋 Изменения:"
echo "Старая ссылка: $OLD_REPO"
echo "Новая ссылка:  $NEW_REPO"
echo ""

# Подтверждение
read -p "Продолжить? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Отменено"
    exit 1
fi

echo ""
echo "🔧 Обновление файлов..."

# Обновляем все файлы одной командой
find . -name "*.md" -o -name "*.sh" | grep -v ".git" | xargs sed -i.bak "s|$OLD_REPO|$NEW_REPO|g"
find . -name "*.md" -o -name "*.sh" | grep -v ".git" | xargs sed -i.bak "s|$OLD_USER|$NEW_USER|g"
find . -name "*.md" -o -name "*.sh" | grep -v ".git" | xargs sed -i.bak "s|$OLD_REPO_NAME|$NEW_REPO_NAME|g"

echo "✅ Обновление завершено!"
echo ""
echo "🧹 Удаление резервных файлов..."
find . -name "*.bak" -delete

echo ""
echo "📋 Следующие шаги:"
echo "1. Проверьте изменения: git diff"
echo "2. Добавьте в коммит: git add ."
echo "3. Создайте коммит: git commit -m 'feat: Update GitHub repository links'"
echo "4. Отправьте на GitHub: git push origin main"
